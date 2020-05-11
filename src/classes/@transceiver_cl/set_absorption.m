function set_absorption(trans_obj,envdata)

if isnumeric(envdata)    
    if all(isnan(envdata))
       envdata= trans_obj.get_params_value('Absorption',[]);
    end
    
    if numel(envdata)==numel(trans_obj.Range)
        trans_obj.Alpha=envdata(:);
        if numel(unique(envdata))==1
            trans_obj.Alpha_ori='constant';
        else
            trans_obj.Alpha_ori='profile';
        end
    else
        trans_obj.Alpha=nanmean(envdata)*ones(size(trans_obj.Range));
        trans_obj.Alpha_ori='constant';
    end    
elseif isa(envdata,'env_data_cl')
    [alpha,ori]=trans_obj.compute_absorption(envdata);
    trans_obj.Alpha=alpha;
    trans_obj.Alpha_ori=ori;
else
    [alpha,ori]=trans_obj.compute_absorption();
    trans_obj.Alpha=alpha;
    trans_obj.Alpha_ori=ori;
end

switch trans_obj.Alpha_ori
    case 'constant'
       trans_obj.Params.Absorption=nanmean(trans_obj.Alpha)*ones(size(trans_obj.Params.Absorption)); 
end

end