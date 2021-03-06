%% detect_bottom_supervised.m
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
% * |cbackdata|: TODO: write description and info on variable
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
% * 2017-06-28: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function detect_bottom_supervised(src,~,main_figure)
if check_axes_tab(main_figure)==0
    return;
end
if~(strcmpi(src.SelectionType,'Normal'))
    return;
end

update_algos(main_figure,'algo_name',{'BottomDetectionV2'});

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
context_menu=axes_panel_comp.bad_transmits.UIContextMenu;
childs=findobj(context_menu,'Type','uimenu');

for i=1:length(childs)
    if strcmp(childs(i).Checked,'on')
        dr=childs(i).UserData;
        break;
    end
    
end

ah=axes_panel_comp.main_axes;
echo=axes_panel_comp.main_echo;

di=1/2;


clear_lines(ah);

 [cmap,col_ax,col_box,col_grid,col_bot,col_txt,line_col]=init_cmap(curr_disp.Cmap);
 


xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');
ratio=4*diff(y_lim)/diff(x_lim);

nb_pings=numel(xdata);
nb_samples=numel(ydata);
old_bot=trans_obj.Bottom;

yinit=nan(1,nb_pings);
if isempty(old_bot.Sample_idx)
    old_bot.Sample_idx=nan(1,nb_pings);
end

bot=old_bot;

cp = ah.CurrentPoint;
ping_init =round(cp(1,1));
sample_init=round(cp(1,2));

if ping_init<x_lim(1)||ping_init>x_lim(end)||sample_init<y_lim(1)||sample_init>y_lim(end)
    return;
end

switch src.SelectionType
    case 'normal'
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb);
    otherwise
        return;
        
end

clear_lines_temp(ah);
delete(findobj(ah,'Tag','BrushedArea'));
hp=plot(ah,xdata,yinit+di,'color',line_col,'linewidth',1,'Tag','bottom_temp','linewidth',2);
%rect=rectangle(ah,'Position',[ping_init-dr sample_init-ratio*dr 2*dr dr*2*ratio],'EdgeColor',line_col,'tag','BrushedArea');
x_box=[ping_init-dr ping_init-dr ping_init+dr ping_init+dr];
y_box=[sample_init-ratio*dr sample_init+ratio*dr sample_init+ratio*dr sample_init-ratio*dr];
rect=patch(ah,'XData',x_box,'YData',y_box,'FaceColor',col_box,'tag','BrushedArea','FaceAlpha',0.5,'EdgeColor',col_box);
wbmcb([],[])
    function wbmcb(~,~)

        cp=ah.CurrentPoint;
        ping_new =round(cp(1,1));
        sample_new=round(cp(1,2));
        x_box=[ping_new-dr ping_new-dr ping_new+dr ping_new+dr];
        y_box=[sample_new-ratio*dr sample_new+ratio*dr sample_new+ratio*dr sample_new-ratio*dr];
%         rect.Position=[ping_new-dr sample_new-ratio*dr 2*dr dr*2*ratio];
        set(rect,'XData',x_box,'YData',y_box);
        
        [idx_pings,idx_r]=get_pr(ping_new,sample_new);

        if ping_new<xdata(1)||ping_new>xdata(end)||sample_new<ydata(1)||sample_new>ydata(end)
            return;
        end
        
        output_struct= trans_obj.apply_algo('BottomDetectionV2','reg_obj',region_cl('Idx_r',idx_r,'Idx_pings',idx_pings),'force_ignore_status_bar',1);
       
        yinit(idx_pings)=output_struct.bottom;
        
        if isvalid(hp)
            set(hp,'XData',xdata(idx_pings),'YData',yinit(idx_pings)+di);
        else
            hp=plot(ah,xdata(idx_pings),yinit(idx_pings)+di,'color',line_col,'linewidth',1,'Tag','bottom_temp','linewidth',2);
        end
        
        
        bot.Sample_idx(idx_pings)=yinit(idx_pings);
        end_bottom_edit(0)
    end


    function wbucb(~,~)
        delete(hp);
        delete(rect)
        end_bottom_edit(1);
    end


    function [idx_pings,idx_r]=get_pr(ping1,sample1)
        
        idx_pings=round((ping1-dr):(ping1+dr));
        idx_r=round((sample1-dr*ratio):(sample1+dr*ratio));
        
        idx_pings(idx_pings>nb_pings|idx_pings<1)=[];
        idx_r(idx_r>nb_samples|idx_r<1)=[];
        
    end

    function end_bottom_edit(val)
        
        if val>0
            replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
            replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1);
        end
        
        trans_obj.Bottom=bot;
        curr_disp.Bot_changed_flag=1;
        display_bottom(main_figure,{'main' 'mini' curr_disp.ChannelID});
        
        
        if val>0
            
            
            
            add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);
            
            set_alpha_map(main_figure,'update_bt',0);
            update_info_panel([],[],1);
        else
            %set_alpha_map(main_figure,'main_or_mini','main');
        end

    end
    


end
