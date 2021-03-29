push_beam_power = optimizableVariable('push_beam_power', [ 1 20 ]);
push_beam_radius = optimizableVariable('push_beam_radius', [ 0.1 10 ]);
push_beam_detuning = optimizableVariable('push_beam_detuning', [ -300 50 ]);
cooling_beam_detuning = optimizableVariable('cooling_beam_detuning', [ -180 -15 ]);
quadrupole_gradient = optimizableVariable('quadrupole_gradient', [ 10 100 ]);
vars = [ push_beam_power, push_beam_radius, push_beam_detuning, cooling_beam_detuning, quadrupole_gradient ];

hours = 2;
result = bayesopt(...
    @(x) asses(x), ...
    vars, ...
    'NumSeedPoints', 30, ...
    'MaxTime', 60*60*hours, ...
    'MaxObjectiveEvaluations', inf, ...
    'OutputFcn', @saveToFile, ...
    'SaveFileName', 'optimot.mat');

[best,val] = bestPoint(result);

save('result_2d.mat', 'result', 'best', 'val');
set(gcf, 'Color', 'w');
saveas(gcf, 'result_2d.pdf');

%%
% Run best parameters

params = table2struct(best);
params.use_3d_quadrupole = false;
mot.simulate(params);
util.animate('SimulationRegion', [ -0.1 0.1; -0.1 0.1; -0.3 0.3 ], 'SaveVideo', 1);

%% 
% Define additional functions.

function score = asses(x)

% Run the simulation for parameters.
p = table2struct(x);
mot.simulate(p);

% Analyse trajectories, count atoms which were ejected by source.
output = util.read_output('pos.txt');
ids = [];
for frame=output'
    captured = frame.vec(:,3) > 0.30;
    ids = unique([ids; frame.id(captured)]);
end
score = -length(ids);

end