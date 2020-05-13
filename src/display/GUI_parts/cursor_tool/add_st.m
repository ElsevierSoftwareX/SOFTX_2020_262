
function add_st(src,~,main_figure)

if check_axes_tab(main_figure)==0
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');


ah=axes_panel_comp.main_axes;

clear_lines(ah);
clear_lines_temp(ah);

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,line_col]=init_cmap(curr_disp.Cmap);

[trans_obj,~]=layer.get_trans(curr_disp);

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');


nb_pings=length(trans_obj.Time);



xinit=nan(1,nb_pings);
yinit=nan(1,nb_pings);

cp = ah.CurrentPoint;
xinit(1) =cp(1,1);
yinit(1)=cp(1,2);
% x0=xinit(1);
% y0=yinit(1);
u=1;
if xinit(1)<x_lim(1)||xinit(1)>x_lim(end)||yinit(1)<y_lim(1)||yinit(1)>y_lim(end)
    return;
end

add=1;

switch src.SelectionType
    case 'normal'
        hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','bottom_temp','Marker','o','MarkerFaceColor',col_grid,'linestyle','none');
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb_ext);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1,'interaction_fcn',@wbucb);
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',@wbdcb_ext);
%         switch src.SelectionType
%             case 'normal'
%                 add=1;
%             case 'extend'
%                 add=0;
%         end
    otherwise
        return;
end



    function wbmcb_ext(~,~)
        cp=ah.CurrentPoint;
        
        x_tmp=cp(1,1);
        y_tmp=cp(1,2);
        [~, idx_p]=nanmin(abs(x_tmp-xdata));
        
        [~,idx_r]=nanmin(abs(y_tmp-ydata));
        
        xinit(u)=xdata(idx_p);
        yinit(u)=ydata(idx_r);
        

        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
            hp=plot(ah,xinit,yinit,'color',line_col,'linewidth',1,'Tag','bottom_temp','linestyle','none','Marker','o','MarkerFaceColor',col_grid);
        end
        
        
    end

    function wbdcb_ext(~,~)
        [xinit,yinit]=check_xy();
        switch src.SelectionType
            case {'open' 'alt'}
                delete(hp);
                end_st_edit();
                replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
                replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',1);
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@add_st,main_figure});
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
        
        x_f=xinit;
        y_f=yinit;
        

    end

    function wbucb(~,~)
        
        if u==1
            xinit(u)=cp(1,1);
            yinit(u)=cp(1,2);
            u=2;
        end
        
    end


    function end_st_edit()
        
        [~, idx_p]=nanmin(abs(xinit'-xdata),[],2);
        
        [~,idx_r]=nanmin(abs(ydata-yinit));
        
        if add>0
            trans_obj.add_st_from_idx(idx_r,idx_p);
        else
            trans_obj.rm_st_from_idx(idx_r,idx_p);
        end
         delete(hp);
       
        
        curr_disp.setField('singletarget');
        
        display_tracks(main_figure);
        update_st_tracks_tab(main_figure,'histo',1,'st',1);
    end




end
