function survey_input_to_survey_xml(survey_input_obj,varargin)

p = inputParser;

addRequired(p,'survey_input_obj',@(x) isa(x,'survey_input_cl'));
addParameter(p,'xml_filename',fullfile(pwd,'survey_xml.xml'),@ischar);
% addParameter(p,'Author','',@ischar);
% addParameter(p,'Comment','',@ischar);
% addParameter(p,'Main_species','',@ischar);
% addParameter(p,'Title','',@ischar);
addParameter(p,'open_file',true,@islogical);

parse(p,survey_input_obj,varargin{:});


docNode = com.mathworks.xml.XMLUtils.createDocument('survey_processing');
main_node=docNode.getDocumentElement;
main_node.setAttribute('version','1.1');%version 1.1: 13//01/2020: add
survey_node = docNode.createElement('survey');
fields_infos=fields(survey_input_obj.Infos);

survey_input_obj.Infos.Created=datestr(now);

for i=1:length(fields_infos)
    survey_node.setAttribute(fields_infos{i},survey_input_obj.Infos.(fields_infos{i}));
end

main_node.appendChild(survey_node);

options_node = survey_input_obj.Options.survey_options_to_xml_node(docNode,0);

main_node.appendChild(options_node);

for ical=1:length(survey_input_obj.Cal)
    cal_node = docNode.createElement('cal');
    fields_cal=fields(survey_input_obj.Cal(ical));
    for i=1:length(fields_cal)
        if ~iscell(survey_input_obj.Cal(ical).(fields_cal{i}))
            switch fields_cal{i}
                case 'FREQ'
                    cal_node.setAttribute(fields_cal{i},num2str(survey_input_obj.Cal(ical).(fields_cal{i}),'%.0f '));
                otherwise
                    cal_node.setAttribute(fields_cal{i},num2str(survey_input_obj.Cal(ical).(fields_cal{i}),'%.2f '));
            end
        end
    end
    
    main_node.appendChild(cal_node);
end


algo_node = docNode.createElement('algos');
for ial=1:length(survey_input_obj.Algos)
    al_node = docNode.createElement(survey_input_obj.Algos{ial}.Name);
    fields_al=fields(survey_input_obj.Algos{ial}.Varargin);
    for i=1:length(fields_al)
        if isnumeric(survey_input_obj.Algos{ial}.Varargin.(fields_al{i}))||islogical(survey_input_obj.Algos{ial}.Varargin.(fields_al{i}))
            al_node.setAttribute(fields_al{i},num2str(survey_input_obj.Algos{ial}.Varargin.(fields_al{i})));
        elseif ischar(survey_input_obj.Algos{ial}.Varargin.(fields_al{i}))
            al_node.setAttribute(fields_al{i},survey_input_obj.Algos{ial}.Varargin.(fields_al{i}));
        end
    end
    algo_node.appendChild(al_node);
    
end
main_node.appendChild(algo_node);

if ~isempty(survey_input_obj.Regions_WC)
    for iregwc=1:length(survey_input_obj.Regions_WC)
        reg_wc_node = docNode.createElement('regions_WC');
        fields_reg_wc=fields(survey_input_obj.Regions_WC{iregwc});
        for i=1:length(fields_reg_wc)
            if isnumeric(survey_input_obj.Regions_WC{iregwc}.(fields_reg_wc{i}))
                reg_wc_node.setAttribute(fields_reg_wc{i},num2str(survey_input_obj.Regions_WC{iregwc}.(fields_reg_wc{i})));
            else
                reg_wc_node.setAttribute(fields_reg_wc{i},survey_input_obj.Regions_WC{iregwc}.(fields_reg_wc{i}));
            end
        end
        main_node.appendChild(reg_wc_node);
    end
    
end

if ~isempty(survey_input_obj.Snapshots)
    for isnap=1:length(survey_input_obj.Snapshots)
        snap_node = docNode.createElement('snapshot');
        snap_node.setAttribute('number',num2str(survey_input_obj.Snapshots{isnap}.Number));
        snap_node.setAttribute('folder',survey_input_obj.Snapshots{isnap}.Folder);
        if iscell(survey_input_obj.Snapshots{isnap}.Type)
            t=strjoin(survey_input_obj.Snapshots{isnap}.Type,' and ');
        else
            t=survey_input_obj.Snapshots{isnap}.Type;
        end
        snap_node.setAttribute('type',t);
        if isfield(survey_input_obj.Snapshots{isnap},'Cal')
            cal_node=docNode.createElement('cal');
            for ical=1:length(survey_input_obj.Snapshots{isnap}.Cal)
                fcal=fieldnames(survey_input_obj.Snapshots{isnap}.Cal);
                for ifif=1:numel(fcal)
                    cal_node.setAttribute('G0',num2str(survey_input_obj.Snapshots{isnap}.Cal.(fcal{ifif}),'%.2f'));
                end
            end
            snap_node.appendChild(cal_node);
        end
        
        for istrat=1:length(survey_input_obj.Snapshots{isnap}.Stratum)
            strat_node = docNode.createElement('stratum');
            strat_node.setAttribute('name',survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Name);
            strat_node.setAttribute('design',survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Design);
            strat_node.setAttribute('radius',num2str(survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Radius));
            for itrans=1:length(survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects)
                trans_node = docNode.createElement('transect');
                trans_node.setAttribute('number',strrep(num2str(survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.number),'  ',';'));
                cell_node = docNode.createElement('cells');
                trans_node.appendChild(cell_node);
                
                for ireg=1:length(survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.Regions)
                    reg_node = docNode.createElement('region');
                    reg=survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.Regions{ireg};
                    f_reg=fieldnames(reg);
                    
                    for uif=1:numel(f_reg)
                        switch f_reg{uif}
                            case {'name' 'Name' 'tag' 'Tag'}
                                reg_node.setAttribute(lower(f_reg{uif}),reg.(f_reg{uif}));
                            case 'IDs'
                                if ischar(reg.IDs)
                                    reg_node.setAttribute('IDs',reg.IDs);
                                else
                                    reg_node.setAttribute('IDs',num2str(reg.IDs));
                                end
                            case 'ver'
                                reg_node.setAttribute('ver',num2str(reg.ver));
                        end
                    end
                    trans_node.appendChild(reg_node);
                end
                
                bot_node = docNode.createElement('bottom');
                bot=survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.Bottom;
                
                if isfield(bot,'ver')
                    bot_node.setAttribute('ver',num2str(bot.ver));
                end
                
                trans_node.appendChild(bot_node);
                
                strat_node.appendChild(trans_node);
                
            end
            snap_node.appendChild(strat_node);
        end
        main_node.appendChild(snap_node);
    end
    [path_f,f,e]=fileparts(p.Results.xml_filename);
    if ~isfolder(path_f)
        try
            stat=mkdir(path_f);
            if stat==0
                path_f=pwd;
            end
        catch
            path_f=pwd;
        end
    end
    f_out=fullfile(path_f,[f e]);
    xmlwrite(f_out,docNode);
    %type(xml_file);
    if p.Results.open_file
        open_txt_file(f_out);
    end
    
    
end