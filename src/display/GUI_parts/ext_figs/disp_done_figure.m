function disp_done_figure(main_figure,str)

s_str=numel(str);

nb_lines=ceil(s_str*8/200);

str_b_w=nanmax(ceil(s_str*8/nb_lines),200);

box_w=str_b_w+40;
btt_w = 40;
btt_h = 20;



QuestFig=new_echo_figure(main_figure,'units','pixels','position',[200 200 box_w 2*btt_h+40+(nb_lines-1)*15],...
    'WindowStyle','modal','Visible','off','resize','off','tag','done');

uicontrol('Parent',QuestFig,...
    'Style','text',...
    'FontWeight','normal',...
    'Position',[(box_w-str_b_w)/2 2*btt_h str_b_w 20+(nb_lines-1)*15],...
    'String',str,'BackgroundColor','w');

uicontrol('Parent',QuestFig,...
    'Style','pushbutton',...
    'Position',[box_w/2-btt_w/2 btt_h/2 btt_w btt_h],...
    'String','OK','callback',@close_fig);
set(QuestFig,'visible','on');
waitfor(QuestFig);
        


end

function close_fig(src,evt)
fig=ancestor(src,'figure');
delete(fig);
end