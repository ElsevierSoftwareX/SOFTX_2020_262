function t=get_time_range(trans_obj,idx_r)

arguments
    trans_obj transceiver_cl
    idx_r {mustBeNumeric}=[]
end
t=(0:(numel(trans_obj.get_transceiver_range())-1))*trans_obj.get_params_value('SampleInterval',1);

if ~isempty(idx_r)
    t=t(idx_r) ;
end

end