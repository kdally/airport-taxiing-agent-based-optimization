
%% MODEL ANALYSIS. JUST CHANGE INPUT LINE 8. 
% output has mean values on first three rows, below row of zeros, below
% coefficient of variation

clear

model = "V3"; % OR, V2, V3, V4, original

raw_table = readtable('Results/Assignment2_basic experiment-table-' + model + '.csv');
raw_cell = table2cell(raw_table(:,4:end));

% IF ERROR, COMMENT LINE 15 AND UNCOMMENT LINE 14
all_conditions = str2double(raw_cell);
%all_conditions = cell2mat(raw_cell);

normal = all_conditions(1:10,:);
high = all_conditions(11:20,:);
asym = all_conditions(21:30,:);

clear raw_table
clear raw_cell
clear all_conditions
coeff_normal = (std(normal)./mean(normal));
coeff_normal(isnan(coeff_normal)) = 0;
mean_normal = mean(normal);

coeff_high = (std(high)./mean(high));
coeff_high(isnan(coeff_high)) = 0;
mean_high = mean(high);

coeff_asym = (std(asym)./mean(asym));
coeff_asym(isnan(coeff_asym)) = 0;
mean_asym = mean(asym);

output = [mean_normal; mean_high; mean_asym; zeros(size(coeff_high)); coeff_normal; coeff_high; coeff_asym];

csvwrite('Results/' + model + '_model.csv',output)

