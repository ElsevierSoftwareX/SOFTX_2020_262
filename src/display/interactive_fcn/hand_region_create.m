%% hand_region_create.m
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
% * |main_figure|: TODO: write description and info on variable
% * |func|: TODO: write description and info on variable
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
function hand_region_create(main_figure,func)
%profile on;
layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

ah=axes_panel_comp.main_axes;


switch main_figure.SelectionType
    case 'normal'
        
    otherwise
        %         curr_disp.CursorMode='Normal';
        return;
end
axes_panel_comp.bad_transmits.UIContextMenu=[];
axes_panel_comp.bottom_plot.UIContextMenu=[];
clear_lines(ah);
 [cmap,col_ax,col_line,col_grid,col_bot,col_txt,~]=init_cmap(curr_disp.Cmap);

[trans_obj,idx_freq]=layer.get_trans(curr_disp);

rr=trans_obj.get_transceiver_range();

cp = ah.CurrentPoint;
u=1;

xinit(1) = cp(1,1);
yinit(1)=cp(1,2);

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');

if xinit(1)<x_lim(1)||xinit(1)>xdata(end)||yinit(1)<y_lim(1)||yinit(1)>y_lim(end)
    return;
end

%set(main_figure,'KeyPressFcn',{@check_esc});

hp=patch(ah,'XData',xinit,'YData',yinit,'FaceColor',col_line,'FaceAlpha',0.4,'EdgeColor',col_line,'linewidth',0.5,'Tag','reg_temp');
txt=text(ah,cp(1,1),cp(1,2),sprintf('%.2f m',rr(nanmin(ceil(cp(1,2)),numel(rr)))),'color',col_line,'Tag','reg_temp');

replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);

    function wbmcb(~,~)
        cp = ah.CurrentPoint;
        
        if cp(1,2)<0
            return;
        end
        
        u=u+1;
        xinit(u) = cp(1,1);
        yinit(u) = nanmin(nanmax(ceil(cp(1,2)),1),numel(rr));
        
        
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
           hp=patch(ah,'XData',xinit,'YData',yinit,'FaceColor',col_line,'FaceAlpha',0.4,'EdgeColor',col_line,'linewidth',0.5,'Tag','reg_temp');
        end
        
        
        
        if isvalid(txt)
            set(txt,'position',[cp(1,1) yinit(u) 0],'string',sprintf('%.2f m',rr(yinit(u))));
        else
            txt=text(ah,cp(1,1),yinit(u),sprintf('%.2f m',rr(yinit(u))),'color',col_line,'Tag','reg_temp');
        end
        
    end

    function wbucb(main_figure,~)
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
      
        x_data_disp=linspace(xdata(1),xdata(end),length(xdata));
        xinit(isnan(xinit))=[];
        yinit(isnan(yinit))=[];
        xinit(xinit>xdata(end))=xdata(end);
        xinit(xinit<xdata(1))=xdata(1);
        
        yinit(yinit>ydata(end))=ydata(end);
        yinit(yinit<ydata(1))=ydata(1);
        
        poly_r=nan(size(yinit));
        poly_pings=nan(size(xinit));
        
        for i=1:length(xinit)
            [~,poly_pings(i)]=nanmin(abs(xinit(i)-double(x_data_disp)));
            [~,poly_r(i)]=nanmin(abs(yinit(i)-double(ydata)));     
        end
        clear_lines(ah)
        delete(txt);
        delete(hp);
        
        if length(poly_pings)<=2
            return;
        end
        
        poly_pings=round([poly_pings poly_pings(1)]);
        poly_r=round([poly_r poly_r(1)]);
        
        feval(func,main_figure,poly_r,poly_pings);
        
% profile off;
% profile viewer;

              
    end

end