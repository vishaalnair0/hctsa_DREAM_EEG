%% Function to obtain consistency from DNV values - revised

function consistency = getConsistency2r(DNV_vector,direction)

DNV_vector_directioncorrected = DNV_vector.*direction;

for d = 1:length(DNV_vector)
    data = DNV_vector_directioncorrected(d);
    if data > 0
        Db(d) = 1;
    elseif data == 0
        Db(d) = 0.5;
    elseif data < 0
        Db(d) = 0;
    end
end
consistency = mean(Db);

end