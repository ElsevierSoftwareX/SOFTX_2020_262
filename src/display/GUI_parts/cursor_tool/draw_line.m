%% draw_line.m
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
function draw_line(src,~,main_figure)

if check_axes_tab(main_figure)==0
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
ah=axes_panel_comp.main_axes;

clear_lines(ah);

 [cmap,col_ax,line_col,col_grid,col_bot,col_txt,~]=init_cmap(curr_disp.Cmap);


[trans_obj,idx_freq]=layer.get_trans(curr_disp);

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();
Range=trans_obj.get_transceiver_range();

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');

nb_pings=length(trans_obj.Time);
line_obj=line_cl('Name',sprintf('Hand Drawn Line %d',numel(layer.Lines)+1),'Range',nan(1,nb_pings),'Time',trans_obj.Time);

xinit=nan(1,nb_pings);
yinit=nan(1,nb_pings);

cp = ah.CurrentPoint;
xinit(1) =cp(1,1);
yinit(1)=cp(1,2);
u=1;
if xinit(1)<x_lim(1)||xinit(1)>xdata(end)||yinit(1)<y_lim(1)||yinit(1)>y_lim(end)
    return;
end

idx_line_tot=[];
switch src.SelectionType
    case {'normal','alt','extend','open'}
        hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','line_temp');
        
        switch src.SelectionType
            case 'normal'
                replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
                replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb);
            case 'extend'
                u=u+1;
                replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',@wbdcb_ext);
            case {'alt','open'}
                end_line_edit();
        end
    otherwise
        [~, idx_line]=nanmin(abs(xinit(1)-xdata));
        [~,idx_r]=nanmin(abs(yinit(1)-ydata));
        line_obj.Range(idx_line)=Range(idx_r);
        end_line_edit();
end
    function wbmcb(~,~)
        u=u+1;
        cp=ah.CurrentPoint;
        xinit(u)=cp(1,1);
        yinit(u)=cp(1,2);
        
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','line_temp');
        end
    end

    function wbmcb_ext(~,~)
        cp=ah.CurrentPoint;
        xinit(u)=cp(1,1);
        yinit(u)=cp(1,2);
        
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','line_temp');
        end
    end

    function wbdcb_ext(~,~)
        
        switch src.SelectionType
            case {'open' 'alt'}
                
                wbucb(src,[]);
                end_line_edit();
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@draw_line,main_figure});
                
                return;
        end
        
        [xinit,yinit]=check_xy();
        u=length(xinit)+1;
        update_line(xinit,yinit);       
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);

        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','line_temp');
        end
        
        
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
        [x_f,y_f]=check_xy();
        update_line(x_f,y_f); 
        end_line_edit();
    end

    function update_line(x_f,y_f)
        if length(x_f)>1
            for i=1:length(x_f)-1
                [~, idx_line]=nanmin(abs(x_f(i)-xdata));
                [~, idx_line_1]=nanmin(abs(x_f(i+1)-xdata));
                
                [~,idx_r]=nanmin(abs(y_f(i)-ydata));
                [~,idx_r1]=nanmin(abs(y_f(i+1)-ydata));
                
                idx_line_tot=(idx_line:idx_line_1);
                
                line_obj.Range(idx_line_tot)=Range(round(linspace(idx_r,idx_r1,length(idx_line_tot))));
            end
        elseif length(x_f)==1
            [~, idx_line]=nanmin(abs(x_f-xdata));
            [~,idx_r]=nanmin(abs(y_f-ydata));
            line_obj.Range(idx_line)=Range(idx_r);
        end
    end

    function end_line_edit()
        delete(hp);
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1);
        if nansum(~isnan(line_obj.Range))<=1
           disp_perso(main_figure,'Only 1 point in line, not saving it.');
           return;
        end
        
        layer.add_lines(line_obj);
        
        update_lines_tab(main_figure);
        display_lines(main_figure);
    end
end
