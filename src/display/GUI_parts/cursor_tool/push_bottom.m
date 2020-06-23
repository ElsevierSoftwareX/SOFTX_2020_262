%% push_bottom.m
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
function push_bottom(src,~,main_figure)

if check_axes_tab(main_figure)==0
    return;
end

if ~(strcmpi(src.SelectionType,'Normal'))
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(curr_disp.Cmap);


context_menu=findobj(src,'Type','uicontextmenu','-and','Tag','btCtxtMenu');
if isempty(context_menu)
    return;
end
childs=findobj(context_menu,'Type','uimenu');

for i=1:length(childs)
    if strcmp(childs(i).Checked,'on')
        radius=childs(i).UserData;
        break;
    end
    
end

ah=axes_panel_comp.echo_obj.main_ax;
echo=axes_panel_comp.echo_obj.echo_surf;

di=-1/2;

clear_lines(ah);

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,line_col]=init_cmap(curr_disp.Cmap);


[trans_obj,idx_freq]=layer.get_trans(curr_disp);

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');


nb_pings=numel(xdata);
nb_samples=numel(ydata);
old_bot=trans_obj.Bottom;

if isempty(old_bot.Sample_idx)
    old_bot.Sample_idx=nan(1,nb_pings);
end

bot=old_bot;
samples_ori=bot.Sample_idx;
xinit=xdata;
yinit=nan(1,nb_pings);

cp = ah.CurrentPoint;
ping_init =round(cp(1,1));
sample_init=round(cp(1,2));


if ping_init<x_lim(1)||ping_init>x_lim(end)||sample_init<y_lim(1)||sample_init>y_lim(end)
    return;
end
diff_r=diff(ylim)/diff(xlim);
xt = radius * cos((0:0.1:2*pi)) + ping_init;
yt = diff_r*radius * sin((0:0.1:2*pi)) + sample_init;

circ=plot(ah,xt,yt,'color','k','linewidth',1,'linestyle','--','color',col_grid);


switch src.SelectionType
    case 'normal'
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb);
    otherwise
        return;
        
end

if sample_init>=samples_ori(ping_init)
    position='above';
    setptr(main_figure,'udrag');
else
    position='below';
    setptr(main_figure,'ddrag');
end
hp=plot(ah,xdata,yinit-1/2,'color',line_col,'linewidth',1,'Tag','bottom_temp');

    function wbmcb(~,~)
        cp=ah.CurrentPoint;
        ping_new =round(cp(1,1));
        sample_new=round(cp(1,2));
        if ping_new<xdata(1)||ping_new>xdata(end)||sample_new<ydata(1)||sample_new>ydata(end)
            return;
        end
        
        sample_new(sample_new>nb_samples)=nb_samples;
        sample_new(sample_new<0)=1;
        
        p0=nanmax(ping_new-radius,1);
        p1=nanmin(ping_new+radius,nb_pings);
        pings_spline=[p0 ping_new p1];
        if length(unique(pings_spline)) < length(pings_spline)
            return;
        end
        samples_spline=[samples_ori(p0) sample_new samples_ori(p1)];
        pings=p0:p1;
        
        samples_new = round(spline(pings_spline,samples_spline,pings));
        samples_new(samples_new>nb_samples)=nb_samples;
        samples_new(samples_new<=0)=1;
        
        %delete(circ);
        
        if isvalid(circ)
            set(circ,'XData',circ.XData-nanmean(circ.XData)+ping_new,...
                'YData',circ.YData-nanmean(circ.YData)+sample_new);
        else
            circ=plot(ah,xt,yt,'color','k','linewidth',1,'linestyle','--');
        end
        
        switch position
            case 'above'
                if sample_new<samples_ori(ping_new)
                    samples_ori(pings)=samples_new;
                    yinit(pings)=samples_new;
                else
                    return;
                end
            case 'below'
                if sample_new>samples_ori(ping_new)
                    samples_ori(pings)=samples_new;
                    yinit(pings)=samples_new;
                else
                    return;
                end
                
        end
        if isvalid(hp)
            set(hp,'XData',xdata,'YData',yinit+di);
        else
            hp=plot(ah,xdata,yinit+di,'color',line_col,'linewidth',1,'Tag','bottom_temp');
        end
    end




    function [x_f, y_f]=check_xy()
        xinit(isnan(yinit))=[];
        yinit(isnan(yinit))=[];
        
        x_rem=xinit>xdata(end)|xinit<xdata(1);
        y_rem=yinit>ydata(end)|yinit<ydata(1);
        
        xinit(x_rem|y_rem)=[];
        yinit(x_rem|y_rem)=[];
        
        [x_f,IA,~] = unique(xinit);
        y_f=yinit(IA);
    end

    function wbucb(~,~)
        delete(circ);
        delete(hp);
        
        [x_f,y_f]=check_xy();
        
        bot.Sample_idx(x_f)=y_f;
        end_bottom_edit();
        
    end





    function end_bottom_edit()
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1);
        trans_obj.Bottom=bot;
        curr_disp.Bot_changed_flag=1;
        
        
        
        add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);
        
        display_bottom(main_figure);
        set_alpha_map(main_figure,'update_bt',0);
        update_info_panel([],[],1);
    end




end
