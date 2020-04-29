%% edit_bottom.m
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
function edit_bottom(src,~,main_figure)


if check_axes_tab(main_figure)==0
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

mouse_state=1;

ah=axes_panel_comp.main_axes;

clear_lines(ah);

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,line_col]=init_cmap(curr_disp.Cmap);
 

[trans_obj,~]=layer.get_trans(curr_disp);

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');
% x0=nanmean(x_lim);
% y0=nanmean(y_lim);
% dx=diff(x_lim);
% dy=diff(y_lim);


nb_pings=length(trans_obj.Time);
old_bot=trans_obj.Bottom;


if isempty(old_bot.Sample_idx)
    old_bot.Sample_idx=nan(1,nb_pings);
end

bot=old_bot;

xinit=nan(1,nb_pings);
yinit=nan(1,nb_pings);
idx_pings=[];
cp = ah.CurrentPoint;
xinit(1) =cp(1,1);
yinit(1)=cp(1,2);
% x0=xinit(1);
% y0=yinit(1);
u=1;
if xinit(1)<x_lim(1)||xinit(1)>x_lim(end)||yinit(1)<y_lim(1)||yinit(1)>y_lim(end)
    return;
end



switch src.SelectionType
    case {'normal','alt','extend'}
        hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','bottom_temp');
        
        switch src.SelectionType
            case 'normal'
                replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);
                replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',@wbdcb_ext);
            case 'alt'
                return;
                %replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
                %replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb_alt);
        end
    otherwise
        [~, idx_bot]=nanmin(abs(xinit(1)-xdata));
        [~,idx_r]=nanmin(abs(yinit(1)-ydata));
        bot.Sample_idx(idx_bot)=idx_r;
        
        end_bottom_edit(1);
end


    function wbmcb_ext(~,~)
        cp=ah.CurrentPoint;
        
        switch mouse_state
            case 1
                u=nansum(~isnan(xinit))+1;
        end
        xinit(u)=cp(1,1);
        yinit(u)=cp(1,2);
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','bottom_temp');
        end
        
        
    end

    function wbdcb_ext(~,~)
        mouse_state=1;
        [x_f,y_f]=check_xy();
        update_bot(x_f,y_f);
        switch src.SelectionType
            case {'open' 'alt'}
                delete(hp);
                replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
                replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1);
                end_bottom_edit(1);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@edit_bottom,main_figure});
                return;
        end
        
        u=nansum(~isnan(xinit))+1;
    end

    function [x_f, y_f]=check_xy()
        xinit(isnan(xinit))=[];
        yinit(isnan(yinit))=[];
        x_rem=xinit>xdata(end)|xinit<xdata(1);
        y_rem=yinit>ydata(end)|yinit<ydata(1);
        
        xinit(x_rem|y_rem)=[];
        yinit(x_rem|y_rem)=[];
        
        [x_f,IA,~] = unique(xinit);
        y_f=yinit(IA);
    end

    function wbucb(~,~)
        mouse_state=0;
        if u==1
            xinit(u)=cp(1,1);
            yinit(u)=cp(1,2);
            u=2;
        end

    end

    function update_bot(x_f,y_f)

        if length(x_f)>1
            for i=1:length(x_f)-1
                [~, idx_bot]=nanmin(abs(x_f(i)-xdata));
                [~, idx_bot_1]=nanmin(abs(x_f(i+1)-xdata));
                
                [~,idx_r]=nanmin(abs(y_f(i)-ydata));
                [~,idx_r1]=nanmin(abs(y_f(i+1)-ydata));
                
                idx_bot=(idx_bot:idx_bot_1);
                
                bot.Sample_idx(idx_bot)=round(linspace(idx_r,idx_r1,length(idx_bot)));
                idx_pings=union(idx_pings,idx_bot);
            end
        elseif length(x_f)==1
            [~, idx_bot]=nanmin(abs(x_f-xdata));
            [~,idx_r]=nanmin(abs(y_f-ydata));
            bot.Sample_idx(idx_bot)=idx_r;
            idx_pings=union(idx_pings,idx_bot);
        end
        
    end



    function end_bottom_edit(val)

        trans_obj.Bottom=bot;
        
        curr_disp.Bot_changed_flag=1;
        
        set_current_layer(layer);
        
        if val>0 
            add_undo_bottom_action(main_figure,trans_obj,old_bot,bot)
            %trans_obj.apply_algo('BottomFeatures','reg_obj',region_cl('Idx_pings',idx_pings,'Idx_r',[1 10]));
        end
        
        display_bottom(main_figure,{'main' 'mini' curr_disp.ChannelID});
        set_alpha_map(main_figure,'update_bt',0);
        update_info_panel([],[],1);
    end



end
