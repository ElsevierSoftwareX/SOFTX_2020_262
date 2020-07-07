function copy_bottom_to_other_freq(layer_obj,idx_bot_freq,idx_other,copy_bt)

if isempty(idx_other)
    return;
end
[bots,ifreq_b]=layer_obj.generate_bottoms_for_other_freqs(idx_bot_freq,idx_other);

for ifreq=1:numel(ifreq_b)
    if copy_bt ==0
        bots(ifreq).Tag = layer_obj.Transceivers(ifreq_b(ifreq)).Bottom.Tag;
    end
    layer_obj.Transceivers(ifreq_b(ifreq)).Bottom=bots(ifreq);
end

end