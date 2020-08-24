function set_absorption(trans_obj,envdata)

if isnumeric(envdata)    
    if all(isnan(envdata))
        FreqStart=(trans_obj.get_params_value('FrequencyStart',1));
        FreqEnd=(trans_obj.get_params_value('FrequencyEnd',1));
        f_c=(FreqStart+FreqEnd)/2;
        d_trans=trans_obj.get_transceiver_depth([],1);
        envdata=seawater_absorption(f_c/1e3, 35, 10, d_trans,'fandg')/1e3;
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


end