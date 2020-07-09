function [echo_obj,trans_obj,text_size,cids]=get_axis_from_cids(main_figure,main_or_mini)

echo_obj=[];
trans_obj=[];
text_size=[];
cids={};
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
if isempty(layer)
    return;
end
secondary_freq=getappdata(main_figure,'Secondary_freq');

for im=1:length(main_or_mini)
    
    ax_comp = [];
    
    switch main_or_mini{im}
        case 'main'
            ax_comp=getappdata(main_figure,'Axes_panel');
            t_size=8;
            cid = curr_disp.ChannelID;
        case 'mini'
            ax_comp=getappdata(main_figure,'Mini_axes');
            t_size=6;
            cid = curr_disp.ChannelID;
        otherwise
            t_size=8; 
            cid = main_or_mini{im};
            if ~isempty(secondary_freq)&&curr_disp.DispSecFreqs>0
                ax_comp =secondary_freq;    
            end
    end
    
    if isempty(ax_comp)||isempty(ax_comp.echo_obj)
        continue;
    end
     
    tags = ax_comp.echo_obj.get_tags();
    idx=(strcmp(main_or_mini{im},tags));
    
    echo_obj_tmp=ax_comp.echo_obj(idx);
    
    for ix=1:length(echo_obj_tmp)
        set(echo_obj_tmp(ix).bottom_line_plot,'vis',curr_disp.DispBottom);
        [trans_obj_temp,~]=layer.get_trans(cid);
        if isempty(trans_obj_temp)
            continue;
        end
        cids{numel(trans_obj)+1}=main_or_mini{im};
        text_size(numel(text_size)+1)=t_size;
        echo_obj=[echo_obj echo_obj_tmp];
        trans_obj=[trans_obj trans_obj_temp];
    end

    
end
    
    
    
   
end