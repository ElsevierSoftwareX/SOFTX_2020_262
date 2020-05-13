%% mark_bad_transmit.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |src|: TODO: write description and info on variable
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function mark_bad_transmit(src,~,main_figure)
%profile on;

if check_axes_tab(main_figure)==0
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
ah=axes_panel_comp.main_axes;

if gca~=ah
    return;
end

clear_lines(ah);


[~,idx_ping_ori]=get_ori(layer,curr_disp,axes_panel_comp.main_echo);
xdata=double(get(axes_panel_comp.main_echo,'XData'));
ydata=double(get(axes_panel_comp.main_echo,'YData'));

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
ping_number=trans_obj.get_transceiver_pings();

old_bot=trans_obj.Bottom;


if strcmp(src.SelectionType,'normal')
    set_val=0;
elseif  strcmp(src.SelectionType,'alt')
    set_val=1;
else
    set_val=0;
end


 [cmap,col_ax,line_col,col_grid,col_bot,col_txt,~]=init_cmap(curr_disp.Cmap);


 switch axes_panel_comp.main_echo.Type
     case 'surface'
         xdata=xdata+1/2;
 end
       

cp = ah.CurrentPoint;


xinit = cp(1,1);
yinit= cp(1,2);

if xinit<xdata(1)||xinit>xdata(end)||yinit<ydata(1)||yinit>ydata(end)
    return
end



switch src.SelectionType
    case {'normal','alt'}
 
        x_bad=[xinit xinit];
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb);
        hp=plot(ah,x_bad,[yinit yinit],'color',line_col,'linewidth',1,'marker','x','tag','bt_temp');
        
    otherwise
        [~,idx_bad]=min(abs(xdata-xinit));

        trans_obj.addBadSector(idx_bad+idx_ping_ori-1,set_val);

        end_bt_edit();
end
    function wbmcb(~,~)
        
       cp = ah.CurrentPoint;

        X = sort([xinit ,cp(1,1)]);
        Y=  [cp(1,2),cp(1,2)];
        
        x_min=nanmin(X);
        x_min=nanmax(xdata(1),x_min);
        
        x_max=nanmax(X);
        x_max=nanmin(xdata(end),x_max);
        
        x_bad=round([x_min x_max]);
        if isvalid(hp)
            set(hp,'XData',x_bad,'YData',Y);
        else
            hp=plot(ah,x_bad,Y,'color',line_col,'linewidth',1,'marker','x','tag','bt_temp');
        end
            
    end

    function wbucb(src,~)
        delete(hp);
        
%         switch obj.Type
%             case 'surface'
%                 x_bad=x_bad+1;
%         end

        [~,idx_start]=min(abs(ping_number-min(x_bad)));
        [~,idx_end]=min(abs(ping_number-max(x_bad)));
        idx_f=(idx_start:idx_end);

        trans_obj.addBadSector(idx_f,set_val);

            
        end_bt_edit()
        
    end

    function end_bt_edit()
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1);
        
        
        new_bot=trans_obj.Bottom;
        curr_disp.Bot_changed_flag=1; 
        
        add_undo_bottom_action(main_figure,trans_obj,old_bot,new_bot);
        
        info_panel_comp=getappdata(main_figure,'Info_panel');
        set(info_panel_comp.percent_BP,'string',trans_obj.bp_percent2str());

        set_alpha_map(main_figure,'update_cmap',0,'update_under_bot',0);
        %update_info_panel([],[],1);
%         profile off;
%         profile viewer;
    end

end
