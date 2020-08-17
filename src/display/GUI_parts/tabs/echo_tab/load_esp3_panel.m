function load_esp3_panel(main_figure,echo_tab_panel)

esp3_tab_comp.esp3_tab=new_echo_tab(main_figure,echo_tab_panel,'Title','ESP3');

adress=sprintf('%s/docs/index.html',whereisEcho());
if ~will_it_work(echo_tab_panel,9.8,false)
    jObject = com.mathworks.mlwidgets.html.HTMLBrowserPanel;
    [esp3_tab_comp.browser,esp3_tab_comp.browser_container] = javacomponent(jObject, [], esp3_tab_comp.esp3_tab);
    set(esp3_tab_comp.browser_container, 'Units','norm', 'Pos',[0,0,1,1]);    
    esp3_tab_comp.browser.setCurrentLocation(adress);
elseif will_it_work(echo_tab_panel,9.8,true)
    g = uigridlayout(esp3_tab_comp.esp3_tab);
    g.RowHeight={'1x'};
    g.ColumnWidth={'1x'};
    esp3_tab_comp.uihtml_h=uihtml(g);
    esp3_tab_comp.uihtml_h.HTMLSource = adress;
    %esp3_tab_comp.uihtml_h.Layout.
end
setappdata(main_figure,'esp3_tab',esp3_tab_comp);

end