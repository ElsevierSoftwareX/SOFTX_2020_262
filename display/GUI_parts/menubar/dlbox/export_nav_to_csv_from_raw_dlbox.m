%% export_nav_to_csv_from_raw_dlbox.m
%
% Open ESP3's "Export navigation (GPS) to .csv from raw files" to do
% exactly that.
%
%% Help
%
% *USE*
%
% Press "Select raw file(s)" choose your .raw files, then choose whether to
% export all nav data or decimated at a chosen interval (first and last GPS
% records will always be exported), and press the "Select output .csv and
% run" button to choose the output file and run the algorithm.
%
% *INPUT VARIABLES*
%
% * |main_figure|: ESP3's main figure handle
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% * Output format for date is "dd/mm/yyyy HH:MM:SS.FFF". Excel doesn't like
% it, but good to keep highest GPS precision
%
% *NEW FEATURES*
%
% * 2018-11-29: (Yoann Ladroit) Added shapefile export plus error
% management. 
% * 2018-11-20: (Alex Schimel).
%
% *EXAMPLE*
%
% NA
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alex Schimel, Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function export_nav_to_csv_from_raw_dlbox(~,~,main_figure)

%% Main Window

gpsdec_fig = new_echo_figure(main_figure, ...
    'Units','pixels',...
    'Position',[100 100 400 150],...
    'Resize','off',...
    'Name','Export navigation (GPS) to .csv/.shp from raw files',...
    'Visible','off',...
    'Tag','gps_dec');


%% Radio buttons

gpsdec_fig_comp.bg = uibuttongroup(gpsdec_fig,...
    'units','normalized',...
    'BackgroundColor','white',...
    'Position',[0 0 1 1]);

gpsdec_fig_comp.rb1 = uicontrol(gpsdec_fig_comp.bg,...
    'Style','radiobutton',...
    'BackgroundColor','white',...
    'String','Extract all navigation data',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'Position',[0.05 0.50 0.8 0.2]);

gpsdec_fig_comp.rb2 = uicontrol(gpsdec_fig_comp.bg,...
    'Style','radiobutton',...
    'BackgroundColor','white',...
    'String','Extract navigation data every',...
    'units','normalized',...
    'HorizontalAlignment','right',...
    'Position',[0.05 0.30 0.9 0.2]);


%% edit box for factor

gpsdec_fig_comp.eb = uicontrol(gpsdec_fig,...
    'Style','edit',...
    'unit','normalized',...
    'position',[0.53 0.32 0.15 0.15],...
    'string',60,...
    'Tag','decf',...
    'callback',{@check_fmt_box,0,inf,60,'%0.1f'});


uicontrol(gpsdec_fig_comp.bg,...
    'Style','text',...
    'BackgroundColor','white',...
    'String','seconds',...
    'units','normalized',...
    'HorizontalAlignment','left',...
    'Position',[0.7 0.32 0.2 0.15]);



%% Get Files button

gpsdec_fig_comp.pb1 = uicontrol(gpsdec_fig,...
    'Style','pushbutton',...
    'units','normalized',...
    'string','Select raw file(s)',...
    'pos',[0.05 0.75 0.9 0.2],...
    'TooltipString','Select raw files',...
    'HorizontalAlignment','left',...
    'BackgroundColor','white',...
    'callback',{@get_raw_files_callback,main_figure});

%% Process button
gpsdec_fig_comp.pb2 = uicontrol(gpsdec_fig,...
    'Style','pushbutton',...
    'units','normalized',...
    'string','Select output .csv./..shp and run',...
    'pos',[0.05 0.05 0.9 0.2],...
    'TooltipString','Select output .csv/.shp',...
    'HorizontalAlignment','left',...
    'BackgroundColor','white',...
    'callback',{@put_csv_file_callback,main_figure});


% disable them by default
gpsdec_fig_comp.rb1.Enable = 'off';
gpsdec_fig_comp.rb2.Enable = 'off';
gpsdec_fig_comp.eb.Enable  = 'off';
gpsdec_fig_comp.pb2.Enable = 'off';

% add default values:
gpsdec_fig_comp.Filename = {};


%% make window visible

set(gpsdec_fig,'visible','on');
setappdata(gpsdec_fig,'gpsdec_fig_comp',gpsdec_fig_comp);


end



function get_raw_files_callback(src,~,main_figure)

% get fig comp
gpsdec_fig = ancestor(src,'figure');
gpsdec_fig_comp = getappdata(gpsdec_fig,'gpsdec_fig_comp');

% get a path
layer = get_current_layer();
if ~isempty(layer)
    [path_lay,~] = layer.get_path_files();
    if ~isempty(path_lay)
        file_path = path_lay{1};
    else
        file_path = pwd;
    end
else
    file_path = pwd;
end

% get files

Filename=get_compatible_ac_files(file_path);

% manage file list
if isempty(Filename)
    return;
end


% add filenames
gpsdec_fig_comp.Filename = Filename;

% enable the rest of uicontrols
gpsdec_fig_comp.rb1.Enable = 'on';
gpsdec_fig_comp.rb2.Enable = 'on';
gpsdec_fig_comp.eb.Enable  = 'on';
gpsdec_fig_comp.pb2.Enable = 'on';

% save in figure
setappdata(gpsdec_fig,'gpsdec_fig_comp',gpsdec_fig_comp);

end





%% Ouptut file prompt and run
function put_csv_file_callback(src,~,main_figure)

% get fig comp
gpsdec_fig = ancestor(src,'figure');
gpsdec_fig_comp = getappdata(gpsdec_fig,'gpsdec_fig_comp');

% get parameters:
Filename = gpsdec_fig_comp.Filename;
if gpsdec_fig_comp.rb2.Value==1
    seconds_between_records = str2double(gpsdec_fig_comp.eb.String);
else
    seconds_between_records = 0;
end
% in days:
days_between_records = seconds_between_records/(24*60*60);

% status bar
show_status_bar(main_figure);
load_bar_comp = getappdata(main_figure,'Loading_bar');

% get a path
layer = get_current_layer();
if ~isempty(layer)
    [path_lay,~] = layer.get_path_files();
    if ~isempty(path_lay)
        file_path = path_lay{1};
    else
        file_path = pwd;
    end
else
    file_path = pwd;
end

% prompt for output file
[outputfilename, outpathname] = uiputfile({'*.csv' 'CSV';'*.shp', 'Shapefile'},...
    'Define output .csv/.shp file for GPS data',...
    fullfile(file_path,'gps_data.csv'));


if isequal(outputfilename,0) || isequal(outpathname,0)
    return
end

output_fullfile = fullfile(outpathname,outputfilename);
if exist(output_fullfile,'file')
    delete(output_fullfile);
end
[~,~,ext_output] = fileparts(output_fullfile);

% make window invisible for the duration of the processing
set(gpsdec_fig,'visible','off');
drawnow

% open each file, read GPS and append to csv file
for ii = 1:length(Filename)
    try
        % read file
        new_layer = open_file_standalone(Filename{ii},{},'GPSOnly',1,'load_bar_comp',load_bar_comp);
        
        % extract and decimate time vector
        time = new_layer.GPSData.Time;
        
        if days_between_records > 0 && ~isempty(time)
            
            idx = false(size(time));
            idx(1) = 1;
            last_idx = 1;
            
            while last_idx ~= length(idx)
                
                step = time(last_idx) + days_between_records;
                
                if step < time(end)
                    last_idx = find(time>step,1,'first');
                    idx(last_idx) = 1;
                else
                    last_idx = length(idx);
                    idx(end) = 1;
                end
                
            end
            
        else
            
            idx = true(size(time));
            
        end
        
        idx=find(idx);
        % total number of records
        if isempty(idx)
           warning('No gps data for  files %s\n',Filename{ii});
        end
        
        numRecords = numel(idx);
        
        % create output structure
       
        [~,filename,ext] = fileparts(new_layer.Filename{1});
        
        switch ext_output
            case '.csv'
                
                output.file = repmat({[filename ext]},[numRecords 1]);
                output.time = cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS.FFF'),num2cell(time(idx)),'UniformOutput',0);
                output.lat  = new_layer.GPSData.Lat(idx);
                output.long = new_layer.GPSData.Long(idx);
                
                ff=fieldnames(output);
                
                for idi=1:numel(ff)
                    if isrow(output.(ff{idi}))
                        output.(ff{idi})=output.(ff{idi})';
                    end
                end
                
                % write (append) structure to file
                struct2csv(output,output_fullfile,0,'a');
                clear output
            case '.shp'
                if ~isempty(idx)
                    field=genvarname(filename);
                    Lines.(field)=new_layer.GPSData.gps_to_geostruct(idx);
                    Lines.(field).Filename=[filename ext];
                end
        end
        
    catch err
        
        warning('Could not save gps data for files %s\n',Filename{ii});
        print_errors_and_warnings(1,'error',err)
    end
end

switch ext_output
    case '.shp'
        LineIDs = fieldnames(Lines);
        i = 1;
        for LineIndex = 1:numel(LineIDs)
            
            LineID = LineIDs{LineIndex};
            Line = Lines.(LineID);
            
            if i==1
                LinesArray = repmat(Line, numel(LineIDs), 1 );
            else
                LinesArray(i) = Line;
            end
            i = i + 1;
        end
        
        shapewrite(LinesArray,output_fullfile);
end

hide_status_bar(main_figure);

% destroy window
close(gpsdec_fig);


end