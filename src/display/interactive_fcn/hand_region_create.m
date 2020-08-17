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

curr_disp=get_esp3_prop('curr_disp');

[echo_obj,trans_obj,~,~]=get_axis_from_cids(main_figure,{'main'});
ah=echo_obj.main_ax;


switch main_figure.SelectionType
    case 'normal'
        
    otherwise
        %         curr_disp.CursorMode='Normal';
        return;
end
echo_obj.echo_bt_surf.UIContextMenu=[];
echo_obj.bottom_line_plot.UIContextMenu=[];

clear_lines(ah);

[cmap,col_ax,col_line,col_grid,col_bot,col_txt,~]=init_cmap(curr_disp.Cmap);

rr=trans_obj.get_transceiver_range();

u=1;

[x,y,idx_p,idx_r] = echo_obj.get_main_ax_cp(trans_obj);

if isempty(idx_p)||isempty(idx_r)
    return;
end

xinit(1) = idx_p;
yinit(1) = idx_r;

%set(main_figure,'KeyPressFcn',{@check_esc});

hp=patch(ah,'XData',xinit,'YData',yinit,'FaceColor',col_line,'FaceAlpha',0.4,'EdgeColor',col_line,'linewidth',0.5,'Tag','reg_temp');
txt=text(ah,x,y,sprintf('%.2f m',rr(idx_r)),'color',col_line,'Tag','reg_temp');

replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);

    function wbmcb(~,~)

        [x,y,idx_p,idx_r] = echo_obj.get_main_ax_cp(trans_obj);

        if isempty(idx_p)||isempty(idx_r)
            return;
        end
        
        u=u+1;
        xinit(u) = idx_p;
        yinit(u) = idx_r;
             
        if isvalid(hp)
            set(hp,'XData',xinit,'YData',yinit);
        else
           hp=patch(ah,'XData',xinit,'YData',yinit,'FaceColor',col_line,'FaceAlpha',0.4,'EdgeColor',col_line,'linewidth',0.5,'Tag','reg_temp');
        end
        
           
        if isvalid(txt)
            set(txt,'position',[x y 0],'string',sprintf('%.2f m',rr(yinit(u))));
        else
            txt=text(ah,x,y,sprintf('%.2f m',rr(yinit(u))),'color',col_line,'Tag','reg_temp');
        end
        
    end

    function wbucb(main_figure,~)
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
      
       
        clear_lines(ah)
        delete(txt);
        delete(hp);
        
        if length(xinit)<=2
            return;
        end
        
        xinit=round([xinit xinit(1)]);
        yinit=round([yinit yinit(1)]);
        
        feval(func,main_figure,yinit,xinit);
        
% profile off;
% profile viewer;

              
    end

end