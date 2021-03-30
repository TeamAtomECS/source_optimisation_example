function output = parse( varargin )
%PARSE Parses parameters for the MOT simulation and fills in defaults.
% 
%  Syntax: output = parse( varargin )

ip = inputParser;
ip.addParameter('push_beam_power', 15);
ip.addParameter('push_beam_detuning', 0);
ip.addParameter('push_beam_radius', 0.6);
ip.addParameter('cooling_beam_detuning', -120);
ip.addParameter('cooling_beam_radius', 33.0 ./ (2 * (2.^0.5)));
ip.addParameter('quadrupole_gradient', 63);
ip.addParameter('push_beam_offset', 0);
ip.addParameter('atom_number', int32(1e6));
ip.addParameter('oven_velocity_cap', 230);
ip.addParameter('microchannel_radius', 0.2);
ip.addParameter('microchannel_length', 4);
ip.StructExpand = 1;
ip.parse(varargin{:});
output = ip.Results;

end