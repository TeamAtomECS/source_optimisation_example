%% Plot Results
% Plots results from the source optimisation example.
%
% You should first run mot.optimise2D to generate the results file.

load('result_2d.mat');
p = table2struct(best);
p = mot.parse(p);
mot.simulate(p);

%%
% Load trajectories

pos = utils.read_output('pos.txt');
ids = [];
for frame=pos'
    captured = frame.vec(:,3) > 0.25;
    ids = unique([ids; frame.id(captured)]);
end

% Build trajectories of each atom
trajectories = {};
for id=ids'
    trajectory = zeros(0,3);
    for i=1:length(pos)
        index = find(pos(i).id == id);
        if ~isempty(index)
            trajectory(end+1,:)=pos(i).vec(index,:);
        end
    end
    trajectories{end+1} = trajectory;
end

vel = utils.read_output('vel.txt');

% Color code by initial velocity
colors = {};
cmap = parula();
vmax = 140;
for id=ids'
    index = find(vel(1).id == id);
    velocity = vel(1).vec(index,:);
    v = sum(velocity.^2).^0.5;
    colors{end+1} = interp1(vmax*linspace(0, 1, length(cmap)), cmap, v, 'linear');
end
    

%%
% Plot a figure showing the evolution of the machine learning algorithm

clf;
set(gcf, 'Units', 'centimeters');
pos = get(gcf, 'Position');
set(gcf, 'Position', [ pos(1) pos(2) 9 12 ]);
set(gca, 'Units', 'centimeters', 'Position', [ 1.2 7.2 7.2 4.4 ]);

plot(result.ObjectiveMinimumTrace); hold on;
plot(result.ObjectiveTrace, 'k.', 'Color', [ 0.4 0.6 0.8 ])
xlabel('iteration number', 'Interpreter', 'latex');
ylabel('cost function', 'Interpreter', 'latex');

% Improve figure aesthetics
set(gcf, 'Color', 'w');
set(get(gca, 'XAxis'), 'TickLabelInterpreter', 'latex');
set(get(gca, 'YAxis'), 'TickLabelInterpreter', 'latex');
box(gca, 'on');
grid(gca, 'on');
set(gca, 'GridLineStyle', ':');

% Plot trajectories of best results
axes('Units', 'centimeters', 'Position', [ 1.2 1.2 7.2 5 ]);
for i=1:length(trajectories)
   p = trajectories{i}*1e3;
   plot(p(:,1), p(:,3), '-', 'Color', colors{i}); hold on; 
end
xlim([ -10 20 ]);
ylim([ -30 40 ]);

xlabel('$x$ (mm)', 'Interpreter', 'latex');
ylabel('$z$ (mm)', 'Interpreter', 'latex');
set(gcf, 'Color', 'w');
set(get(gca, 'XAxis'), 'TickLabelInterpreter', 'latex');
set(get(gca, 'YAxis'), 'TickLabelInterpreter', 'latex');
box(gca, 'on');
grid(gca, 'on');
set(gca, 'GridLineStyle', ':');

annotation('textbox', 'Units', 'Centimeters', 'Position', [ 1.3 1.7 1 1 ], 'String', '$\rightarrow$', 'Interpreter', 'Latex', 'FontSize', 20, 'LineStyle', 'none');
annotation('textbox', 'Units', 'Centimeters', 'Position', [ 3.9 5.1 1 1 ], 'String', '$\uparrow$', 'Interpreter', 'Latex', 'FontSize', 20, 'LineStyle', 'none');

annotation('textbox', 'Units', 'Centimeters', 'Position', [ -0.1 11.1 1 1 ], 'String', '(a)', 'Interpreter', 'Latex', 'FontSize', 11, 'LineStyle', 'none');
annotation('textbox', 'Units', 'Centimeters', 'Position', [ -0.1 5.5 1 1 ], 'String', '(b)', 'Interpreter', 'Latex', 'FontSize', 11, 'LineStyle', 'none');

%%
% Save figure

set(gcf, 'Units', 'centimeters');
pos = get(gcf, 'Position');
w = pos(3);
h = pos(4);
p = 0.01;
set(gcf,...
    'PaperUnits','centimeters',...
    'PaperPosition',[p*w p*h w h],...
    'PaperSize',[w*(1+2*p) h*(1+2*p)]);
set(gcf, 'Renderer', 'painters')
saveas(gcf, 'optimiser.pdf')