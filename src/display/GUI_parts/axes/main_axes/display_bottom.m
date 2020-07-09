
function display_bottom(main_figure,varargin)

layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);


info_panel_comp=getappdata(main_figure,'Info_panel');
set(info_panel_comp.percent_BP,'string',trans_obj.bp_percent2str());

if ~isempty(varargin)
    if ischar(varargin{1})
        switch varargin{1}
            case 'both'
                main_or_mini={'main' 'mini' curr_disp.ChannelID};
            case 'mini'
                main_or_mini={'mini'};
            case 'main'
                main_or_mini={'main' curr_disp.ChannelID};
            case 'all'
                main_or_mini=union({'main' 'mini'},layer.ChannelID);
        end
    elseif iscell(varargin{1})
        main_or_mini=varargin{1};
    end
else
    main_or_mini=union({'main' 'mini'},layer.ChannelID);
end

[echo_obj,trans_obj_tot,text_size,cids]=get_axis_from_cids(main_figure,main_or_mini);
[~,~,~,~,col_bot,~,~]=init_cmap(curr_disp.Cmap);

for iax=1:length(echo_obj)
    
    trans_obj=trans_obj_tot(iax);
    echo_obj(iax).display_echo_bottom(trans_obj,'curr_disp',curr_disp,'col_bot',col_bot);
   
end

end






