function simulate(parameters)
%SIMULATE Performs the simulation with given parameters.

parameters = mot.parse(parameters);

fH = fopen('input.json', 'w');
fprintf(fH, '%s', jsonencode(parameters));
fclose(fH);

name = 'mot';
system(sprintf('cargo run --example %s --release', name));

end