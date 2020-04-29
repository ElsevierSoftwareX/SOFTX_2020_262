function warndlg_perso(main_figure,tt_str,war_str,varargin)

if isempty(varargin)
    timeout=5;
else
    timeout=varargin{1};
end
if ~isempty(main_figure)
    curr_disp=get_esp3_prop('curr_disp');
    if ~isempty(curr_disp)
        font=curr_disp.Font;
    cmap=curr_disp.Cmap;
    else
       font=[];
       cmap=[];
    end
else
           font=[];
       cmap=[];
end

s_str=numel(war_str);

nb_lines=ceil(s_str*8/250);

str_b_w=nanmax(ceil(s_str*8/nb_lines),250);

box_w=str_b_w+40;

war_fig=new_echo_figure(main_figure,'units','pixels','position',[200 200 box_w 40+nb_lines*20],...
    'WindowStyle','modal','Visible','on','resize','off','tag','warning','Name',sprintf('WARNING %s',tt_str));

uicontrol('Parent',war_fig,...
    'Style','text',...
    'Position',[(box_w-str_b_w)/2 20 str_b_w nb_lines*20],...
    'String',war_str);
disp(war_str);
format_color_gui(war_fig,font,cmap);
drawnow;

fig_timer=timer;
fig_timer.UserData.timeout = timeout;
fig_timer.UserData.tt_str = tt_str;
fig_timer.UserData.t0 = now;
fig_timer.TimerFcn = {@update_fig_name,war_fig};
fig_timer.StopFcn = @(src,evt) delete(src);
fig_timer.Period = 1;
fig_timer.ExecutionMode= 'fixedSpacing';

if ishghandle(war_fig)
    % Go into uiwait if the figure handle is still valid.
    % This is mostly the case during regular use.
    c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
    fig_timer.start;
    uiwait(war_fig,timeout);
    if isvalid(fig_timer)
    stop(fig_timer);
    delete(fig_timer)
    delete(c);
    else
        clear fig_timer;
    end
end

delete(war_fig);
drawnow; % Update the view to remove the closed figure (g1031998)


end
function decision_callback(obj, evd) %#ok
  set(gcbf,'UserData',get(obj,'String'));
  uiresume(gcbf);
end
    

function update_fig_name(src,evt,fig)
t=abs((now-src.UserData.t0)*60*60*24);
if t<src.UserData.timeout
    str_name=sprintf('%s (%.0fs)',src.UserData.tt_str,abs(t-src.UserData.timeout));
    fig.Name=str_name;
end
end


