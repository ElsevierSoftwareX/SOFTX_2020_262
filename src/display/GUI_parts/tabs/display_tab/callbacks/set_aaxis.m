function set_aaxis(~,~,main_figure)
display_tab_comp=getappdata(main_figure,'Display_tab');

curr_disp=get_esp3_prop('curr_disp');

aax=str2double(get([display_tab_comp.aaxis_down display_tab_comp.aaxis_up],'String'));
if aax(2)<aax(1)||isnan(aax(1))||isnan(aax(2))
    aax=curr_disp.BeamAngularLimit;
    set(display_tab_comp.aaxis_up,'String',num2str(aax(2),'%.0f'));
    set(display_tab_comp.aaxis_down,'String',num2str(aax(1),'%.0f'));
    return;
end

curr_disp.BeamAngularLimit = aax;

end