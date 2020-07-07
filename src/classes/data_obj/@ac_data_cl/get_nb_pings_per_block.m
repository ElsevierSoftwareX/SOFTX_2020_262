function nb_pings=get_nb_pings_per_block(data_obj)

block_id=unique(data_obj.BlockId);

nb_pings=nan(1,length(block_id));

for fi=1:length(block_id)
    nb_pings(fi)=nansum(data_obj.BlockId==block_id(fi));
end

end