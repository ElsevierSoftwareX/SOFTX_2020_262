
%% Function
function pan_cback(src,~,main_figure)

% main_figure=ancestor(src,'figure');
layer=get_current_layer();
if isempty(layer)
    return;
end

axes_panel_comp=getappdata(main_figure,'Axes_panel');

ah=axes_panel_comp.main_axes;


switch src.SelectionType
    case 'normal'
        pt0 = ah.CurrentPoint;
        
        % exit if cursor outside of window
        if pt0(1,1)<ah.XLim(1) || pt0(1,1)>ah.XLim(2) || pt0(1,2)<ah.YLim(1) || pt0(1,2)>ah.YLim(2)
            return;
        end
        
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb_pan);
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmfcb_pan,'Pointer','closedhand');
        
        
    otherwise
        
        return;
end

    function wbmfcb_pan(src,~)
        %setptr(main_figure,'hand');
         pt = ah.CurrentPoint;
        if pt(1,1)<ah.XLim(1) || pt(1,1)>ah.XLim(2) || pt(1,2)<ah.YLim(1) || pt(1,2)>ah.YLim(2)
            return;
        end
        xlim = ah.XLim;
        ylim = ah.YLim;
       
        xlim_n = xlim-(pt(1,1)-pt0(1,1));
        ylim_n = ylim-(pt(1,2)-pt0(1,2));
        set(ah,'XLim',xlim_n,'YLim',ylim_n);
        
    end


    function wbucb_pan(~,~)

        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        
    end



end