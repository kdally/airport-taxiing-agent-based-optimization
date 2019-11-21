
%% MODEL ANALYSIS. JUST CHANGE FILE NAME LINE 5 and 30

clear
raw_table = readtable('Results/Assignment2_basic experiment-table-or.csv');
raw_cell = table2cell(raw_table(:,4:end));

% IF ERROR, UNCOMMENT LINE 9 AND COMMENT LINE 10
%all_conditions = str2double(raw_cell);
all_conditions = cell2mat(raw_cell);

normal = all_conditions(1:10,:);
high = all_conditions(11:20,:);
asym = all_conditions(21:30,:);

clear raw_table
clear raw_cell
clear all_conditions
coeff_normal = array2table(std(normal)./mean(normal));
mean_normal = mean(normal);

coeff_high = array2table(std(high)./mean(high));
mean_high = mean(high);

coeff_asym = array2table(std(asym)./mean(asym));
mean_asym = mean(asym);

output = [mean_normal; mean_high; mean_asym]; 

%output2 = [coeff_normal; coeff_high, coeff_asym];

xlswrite('Results/orginal_model.xlsx',output)




