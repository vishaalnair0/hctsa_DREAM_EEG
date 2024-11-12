%% Function to compute DNVs for one participant

function DNV = getDNV(dreamful,dreamless)

row_counter = 1;
for i = 1:size(dreamful,1)
    value_row = dreamful(i,:);
    list_values = repmat(value_row,3,1);

    v_dreamful{row_counter}= list_values;
    row_counter = row_counter + 1;
end
values_dreamful = vertcat(v_dreamful{:});

values_dreamless = repmat(dreamless,3,1);

DNV = values_dreamful - values_dreamless;

end