function c=get_soundspeed(trans_obj,idx_r)

arguments
    trans_obj transceiver_cl
    idx_r {mustBeNumeric}=[]
end
c=2*diff(trans_obj.get_transceiver_range())./trans_obj.get_params_value('SampleInterval',1,1);
c=[c;c(end)];
if ~isempty(idx_r)
    c=c(idx_r) ;
end

end