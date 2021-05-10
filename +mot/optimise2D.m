push_beam_power = optimizableVariable('push_beam_power', [ 1 20 ]);
push_beam_radius = optimizableVariable('push_beam_radius', [ 0.1 10 ]);
push_beam_detuning = optimizableVariable('push_beam_detuning', [ -300 50 ]);
cooling_beam_detuning = optimizableVariable('cooling_beam_detuning', [ -180 -15 ]);
quadrupole_gradient = optimizableVariable('quadrupole_gradient', [ 10 100 ]);
vars = [ push_beam_power, push_beam_radius, push_beam_detuning, cooling_beam_detuning, quadrupole_gradient ];

% Table of initial conditions to start the optimisation with ok parameters.
initial = [
    11 4.7 -70 -81 63;
    11 4.7 -70 -81 20;
    11 4.7 -70 -81 40;
    11 4.7 -70 -60 63;
    11 4.7 -70 -60 20;
    11 4.7 -70 -60 40;
    ];
        
initial = array2table(initial);
initial.Properties.VariableNames = {vars.Name};

hours = 1;
result = bayesopt(...
    @(x) asses(x), ...
    vars, ...
    'NumSeedPoints', 30, ...
    'MaxTime', 60*60*hours, ...
    'MaxObjectiveEvaluations', inf, ...
    'OutputFcn', @saveToFile, ...
    'InitialX', initial, ...
    'SaveFileName', 'optimot.mat');

[best,val] = bestPoint(result);

save('result_2d.mat', 'result', 'best', 'val');
set(gcf, 'Color', 'w');
saveas(gcf, 'result_2d.pdf');

%%
% Run best parameters

load('result_2d.mat');
params = table2struct(best);
score = asses(best);
utils.animate('SimulationRegion', [ -0.1 0.1; -0.1 0.1; -0.3 0.3 ], 'SaveVideo', 0, 'AxisView', [ 0 0 ]);

%% 
% Define additional functions.

function score = asses(x)

% Run the simulation for parameters.
p = table2struct(x);
p = mot.parse(p);
mot.simulate(p);

% Analyse trajectories, count atoms which were ejected by source.
output = utils.read_output('pos.txt');
ids = [];
for frame=output'
    captured = frame.vec(:,3) > 0.25;
    ids = unique([ids; frame.id(captured)]);
end
score = -double(length(ids))/double(p.atom_number);

end