function set_folder_time_zone(main_figure,path_to_db)

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

db_file=fullfile(path_to_db,'echo_logbook.db');
if ~isfile(db_file)
    initialize_echo_logbook_dbfile(path_to_db,[],0);
end
dbconn=sqlite(db_file);
createsurveyTable(dbconn);

sql_command='SELECT TimeZone FROM survey';

tz=dbconn.fetch(sql_command);
if iscell(tz)
    tz=tz{1};
end
if isempty(tz)
    tz=0;
end
dbconn.close();
T=timezones('Etc');
T=sortrows(T,'UTCOffset','descend');

idx=find(T.UTCOffset==tz);

QuestFig=new_echo_figure(main_figure,'units','pixels','position',[200 200 200 200],...
    'WindowStyle','modal','Visible','on','resize','off','tag','timezone_choice');

uicontrol('Parent',QuestFig,...
    'Style','text',...
    'Position',[10 150 180 40],...
    'String','Timezone used in files');

choice_list=uicontrol('Parent',QuestFig,...
    'Style','popup',...
    'string',T.Name,...
    'value',idx,...
    'Position',[10 100 180 40],...
    'Fontsize',14);

uicontrol('Parent',QuestFig,...
    'Position',[40 20 50 25],...
    'String','Set',...
    'Callback',@decision_callback,...
    'KeyPressFcn',@doControlKeyPress , 'Value',0);

noHandle=uicontrol('Parent',QuestFig,...
    'Position',[110 20 50 25],...
    'String','Cancel',...
    'Callback',@decision_callback,'KeyPressFcn',@doControlKeyPress , 'Value',0);
setdefaultbutton(QuestFig, noHandle);
format_color_gui(QuestFig,font,cmap);
drawnow;

if ishghandle(QuestFig)
    % Go into uiwait if the figure handle is still valid.
    % This is mostly the case during regular use.
    c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
    uiwait(QuestFig);
    delete(c);
end
db_file=fullfile(path_to_db,'echo_logbook.db');
dbconn=sqlite(db_file);
sql_command=sprintf('UPDATE survey SET Timezone=%f',T.UTCOffset(choice_list.Value));
dbconn.exec(sql_command);
dbconn.close();

delete(QuestFig);
drawnow; % Update the view to remove the closed figure (g1031998)

end

function decision_callback(obj, evd) %#ok
set(gcbf,'UserData',get(obj,'String'));
uiresume(gcbf);
end

function doControlKeyPress(obj, evd)
switch(evd.Key)
    case {'return'}
        uiresume(gcbf);
    case 'escape'
        delete(gcbf)
end
end
