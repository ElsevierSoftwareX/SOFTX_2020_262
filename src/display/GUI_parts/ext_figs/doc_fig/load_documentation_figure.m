function load_documentation_figure(main_figure)
pos_fig=[0.2 0.1 0.6 0.8];

uibool = will_it_work([],9.8,true);

doc_fig=new_echo_figure(main_figure,...
    'Units','normalized',...
    'Position',pos_fig,...
    'Name','ESP3 Documentation',...
    'Resize','on',...
    'Tag','esp3_doc',...
    'UiFigureBool',uibool,...
    'visible','on');
adress=sprintf('%s/docs/ESP3_User_Guide.htm',whereisEcho());

if ~uibool
    jObject = com.mathworks.mlwidgets.html.HTMLBrowserPanel;
    [doc_fig_comp.browser,doc_fig_comp.browser_container] = javacomponent(jObject, [], doc_fig);
    set(doc_fig_comp.browser_container, 'Units','norm', 'Pos',[0,0,1,1]);
    
    doc_fig_comp.browser.setCurrentLocation(adress);
    doc_fig.Visible='on';
else
    g = uigridlayout(doc_fig);
    g.RowHeight={'1x'};
    g.ColumnWidth={'1x'};
    uihtml_h=uihtml(g);
    uihtml_h.Scrollable = true;
    uihtml_h.HTMLSource = adress;
end

end