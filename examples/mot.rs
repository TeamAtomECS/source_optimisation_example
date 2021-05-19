//! A 2D+ mot configuration, loaded directly from oven.

extern crate atomecs as lib;
extern crate nalgebra;
use lib::atom::{AtomicTransition, Position, Velocity};
use lib::atom_sources::emit::AtomNumberToEmit;
use lib::atom_sources::mass::{MassDistribution, MassRatio};
use lib::atom_sources::oven::{OvenAperture, OvenBuilder};
use lib::laser::force::{EmissionForceConfiguration, EmissionForceOption};
use lib::laser::photons_scattered::ScatteringFluctuationsOption;
use lib::atom_sources::VelocityCap;
use lib::destructor::ToBeDestroyed;
use lib::ecs;
use lib::integrator::Timestep;
use lib::laser::cooling::CoolingLight;
use lib::laser::gaussian::GaussianBeam;
use lib::magnetic::quadrupole::{QuadrupoleField3D};
use lib::output::file;
use lib::output::file::Text;
use lib::shapes::Cuboid;
use lib::sim_region::{SimulationVolume, VolumeType};
use nalgebra::{Vector3};
use specs::prelude::*;
use std::fs::read_to_string;
use std::time::Instant;

extern crate serde;
use serde::Deserialize;

/// Parameters describing this simulation
#[derive(Deserialize)]
pub struct SimulationParameters {
    /// Radius of the push beam, units of mm
    pub push_beam_radius: f64,
    /// Power of the push beam, units of mW
    pub push_beam_power: f64,
    /// Detuning of the push beam, units of MHz
    pub push_beam_detuning: f64,
    /// Detuning of the cooling beams, units of MHz, eg: -45.
    pub cooling_beam_detuning: f64,
    /// Gradient of the quadrupole field, Gauss/cm. eg: 65.
    pub quadrupole_gradient: f64,
    /// 1/e radius of the cooling_beam, units of mm
    pub cooling_beam_radius: f64,
    /// Offset of the push beam from the quadrupole node, units of mm.
    pub push_beam_offset: f64,
    /// The number of atoms to simulate. 4e6
    pub atom_number: i32,

    /// Velocity cap of atoms leaving the oven. 230m/s
    pub oven_velocity_cap: f64,

    /// Radius of microchannels in oven nozzle, units of mm. Current Ox oven uses 0.2mm.
    pub microchannel_radius: f64,

    /// Length of microchannels in oven nozzle, units of mm. Current Ox oven uses 4mm.
    pub microchannel_length: f64,
}

fn main() {
    let now = Instant::now();

    let json_str = read_to_string("input.json").expect("Could not open file");
    println!("Loaded json string: {}", json_str);
    let parameters: SimulationParameters = serde_json::from_str(&json_str).unwrap();

    // Create the simulation world and builder for the ECS dispatcher.
    let mut world = World::new();
    ecs::register_components(&mut world);
    ecs::register_resources(&mut world);
    let mut builder = ecs::create_simulation_dispatcher_builder();

    // Configure simulation output.
    builder = builder.with(
        file::new::<Position, Text>("pos.txt".to_string(), 64),
        "",
        &[],
    );
    builder = builder.with(
        file::new::<Velocity, Text>("vel.txt".to_string(), 64),
        "",
        &[],
    );

    let mut dispatcher = builder.build();
    dispatcher.setup(&mut world);

    // Create magnetic field.
    world
        .create_entity()
        .with(QuadrupoleField3D::gauss_per_cm(parameters.quadrupole_gradient, Vector3::z()))
        .with(Position::new())
        .build();

    // Create push beam
    world
        .create_entity()
        .with(GaussianBeam {
            intersection: Vector3::new(parameters.push_beam_offset * 1.0e-3, 0.0, 0.0),
            e_radius: parameters.push_beam_radius * 1.0e-3,
            power: parameters.push_beam_power * 1.0e-3,
            direction: Vector3::z(),
        })
        .with(CoolingLight::for_species(
            AtomicTransition::strontium(),
            parameters.push_beam_detuning,
            -1,
        ))
        .build();

    // Create cooling lasers. Note that one polarisation swaps depending on whether we have a 2D or 3D config.
    let detuning = parameters.cooling_beam_detuning;
    let power = 0.23;
    let radius = parameters.cooling_beam_radius * 1.0e-3;
    world
        .create_entity()
        .with(GaussianBeam {
            intersection: Vector3::new(0.0, 0.0, 0.0),
            e_radius: radius,
            power: power,
            direction: Vector3::new(1.0, 1.0, 0.0).normalize(),
        })
        .with(CoolingLight::for_species(
            AtomicTransition::strontium(),
            detuning,
            1,
        ))
        .build();
    world
        .create_entity()
        .with(GaussianBeam {
            intersection: Vector3::new(0.0, 0.0, 0.0),
            e_radius: radius,
            power: power,
            direction: Vector3::new(1.0, -1.0, 0.0).normalize(),
        })
        .with(CoolingLight::for_species(
            AtomicTransition::strontium(),
            detuning,
            1,
        ))
        .build();
    world
        .create_entity()
        .with(GaussianBeam {
            intersection: Vector3::new(0.0, 0.0, 0.0),
            e_radius: radius,
            power: power,
            direction: Vector3::new(-1.0, 1.0, 0.0).normalize(),
        })
        .with(CoolingLight::for_species(
            AtomicTransition::strontium(),
            detuning,
            1,
        ))
        .build();
    world
        .create_entity()
        .with(GaussianBeam {
            intersection: Vector3::new(0.0, 0.0, 0.0),
            e_radius: radius,
            power: power,
            direction: Vector3::new(-1.0, -1.0, 0.0).normalize(),
        })
        .with(CoolingLight::for_species(
            AtomicTransition::strontium(),
            detuning,
            1,
        ))
        .build();

    let oven_position = -0.083;
        // Create an oven.
        // The oven will eject atoms on the first frame and then be deleted.
        let number_to_emit = parameters.atom_number; //1500000;
        
        world
            .create_entity()
            .with(
                OvenBuilder::new(776.0, Vector3::x())
                    .with_aperture(OvenAperture::Circular {
                        radius: 0.005,
                        thickness: 0.001,
                    })
                    .with_microchannels(parameters.microchannel_length * 1e-3, parameters.microchannel_radius * 1e-3)
                    .build(),
            )
            .with(Position {
                pos: Vector3::new(oven_position, 0.0, 0.0),
            })
            .with(MassDistribution::new(vec![MassRatio {
                mass: 88.0,
                ratio: 1.0,
            }]))
            .with(AtomicTransition::strontium())
            .with(AtomNumberToEmit {
                number: number_to_emit,
            })
            .with(ToBeDestroyed)
            .build();

    // Use a simulation bound so that atoms that escape the capture region are deleted from the simulation.
    world
        .create_entity()
        .with(Position {
            pos: Vector3::new(0.0, 0.0, 0.0),
        })
        .with(Cuboid {
            half_width: Vector3::new(0.1, 0.015, 0.015),
        })
        .with(SimulationVolume {
            volume_type: VolumeType::Inclusive,
        })
        .build();

    // The simulation bound also now includes a small pipe to capture the 2D MOT output properly.
    world
        .create_entity()
        .with(Position {
            pos: Vector3::new(0.0, 0.0, 0.1),
        })
        .with(Cuboid {
            half_width: Vector3::new(0.01, 0.01, 0.4),
        })
        .with(SimulationVolume {
            volume_type: VolumeType::Inclusive,
        })
        .build();

    // Also use a velocity cap so that fast atoms are not even simulated.
    world.insert(VelocityCap {
        value: parameters.oven_velocity_cap,
    });

    // Define timestep
    world.insert(Timestep { delta: 2.0e-6 });
    
    // Add fluctuations
    world.insert(EmissionForceOption::On(EmissionForceConfiguration {
        explicit_threshold: 5,
    }));
    world.insert(ScatteringFluctuationsOption::On);

    // Run the simulation for a number of steps.
    for _i in 0..15_000 {
        dispatcher.dispatch(&mut world);
        world.maintain();
    }

    println!("Simulation completed in {} ms.", now.elapsed().as_millis());
}