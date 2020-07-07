function [echo_obj,trans_obj,text_size,cids]=get_axis_from_cids(main_figure,main_or_mini)

echo_obj=[];

trans_obj={};
text_size=[];
cids={};
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
if isempty(layer)
    return;
end
secondary_freq=getappdata(main_figure,'Secondary_freq');

for im=1:length(main_or_mini)
    switch main_or_mini{im}
        case 'main'
            axes_panel_comp=getappdata(main_figure,'Axes_panel');
            echo_obj_tmp=axes_panel_comp.echo_obj;

            set(axes_panel_comp.echo_obj.bottom_line_plot,'vis',curr_disp.DispBottom);
            
            [trans_obj_temp,~]=layer.get_trans(curr_disp);
            
            if isempty(trans_obj_temp)
                continue;
            end
            cids{numel(trans_obj)+1}=curr_disp.ChannelID;
            trans_obj{numel(trans_obj)+1}=trans_obj_temp;
            text_size(numel(text_size)+1)=8;
        case 'mini'
            mini_axes_comp=getappdata(main_figure,'Mini_axes');
            echo_obj_tmp=mini_axes_comp.echo_obj;            
            [trans_obj_temp,~]=layer.get_trans(curr_disp);
            
            if isempty(trans_obj_temp)
                continue;
            end
            cids{numel(trans_obj)+1}=curr_disp.ChannelID;
            trans_obj{numel(trans_obj)+1}=trans_obj_temp;
            text_size(numel(text_size)+1)=6;
        otherwise
            if ~isempty(secondary_freq)
                if~isempty(secondary_freq.echo_obj)&&curr_disp.DispSecFreqs>0
                    tags = secondary_freq.echo_obj.get_tags();
                    idx=(strcmp(main_or_mini{im},tags));
                    
                    echo_obj_tmp=secondary_freq.echo_obj(idx);
                    
                    for i=1:length(echo_obj_tmp)
                        [trans_obj_temp,~]=layer.get_trans(main_or_mini{im});
                        if isempty(trans_obj_temp)
                            continue;
                        end
                        cids{numel(trans_obj)+1}=main_or_mini{im};
                        trans_obj{numel(trans_obj)+1}=trans_obj_temp;
                        text_size(numel(text_size)+1)=6;
                    end
                else
                    continue;
                end
            else
                continue;
            end
    end
    echo_obj=[echo_obj echo_obj_tmp];
end