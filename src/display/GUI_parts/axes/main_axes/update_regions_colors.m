function update_regions_colors(main_figure,varargin)

layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');


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

[ac_data_col,ac_bad_data_col,in_data_col,in_bad_data_col,txt_col]=set_region_colors(curr_disp.Cmap);

[echo_obj,trans_obj_tot,~,~]=get_axis_from_cids(main_figure,main_or_mini);

reg_uid=layer.get_layer_reg_uid();

for iax=1:length(echo_obj)
    
    reg_text=findobj(echo_obj.get_main_ax(iax),'Tag','region_text');
    if isempty(reg_text)
        continue;
    end
    reg_text(isempty(reg_text))=[];
    [uid_rem,id_rem]=setdiff({reg_text(:).UserData},reg_uid);
    for iuid=1:numel(uid_rem) 
        delete(findobj(echo_obj.get_main_ax(iax),'UserData',uid_rem{iuid}));
    end
    reg_text(id_rem)=[];
    
    set(reg_text,'color',txt_col);
    trans_obj=trans_obj_tot(iax);
    if isempty(trans_obj)
        continue;
    end
    for ireg=1:numel(trans_obj.Regions)
        
        if ismember(trans_obj.Regions(ireg).Unique_ID,curr_disp.Active_reg_ID)
            
            col=ac_data_col;
            switch trans_obj.Regions(ireg).Type
                case 'Data'
                    col=ac_data_col;
                case 'Bad Data'
                    col=ac_bad_data_col;
            end
        else
            switch trans_obj.Regions(ireg).Type
                case 'Data'
                    col=in_data_col;
                case 'Bad Data'
                    col=in_bad_data_col;
            end
        end
        
        reg_patch_ac=findobj(echo_obj.get_main_ax(iax),{'Tag','region'},...
            '-and','UserData',trans_obj.Regions(ireg).Unique_ID,'-and','Type','Polygon','-not','FaceColor',col);
        set(reg_patch_ac,'FaceColor',col,'EdgeColor',col);
    end
end