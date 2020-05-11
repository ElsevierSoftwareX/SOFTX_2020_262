function layers_Str=list_layers(layers,varargin)

p = inputParser;

addRequired(p,'layers',@(obj) isa(obj,'layer_cl'));
addParameter(p,'nb_char',[],@(x) isnumeric(x));

parse(p,layers,varargin{:});
nb_char=p.Results.nb_char;

nb_layers=length(layers);
layers_Str=cell(1,nb_layers);
for ilay=1:nb_layers
    
    switch layers(ilay).Filetype
        case 'ASL'
            t1=floor(layers(ilay).Transceivers(1).Time(1));
            t2=floor(layers(ilay).Transceivers(1).Time(end));
            if t1==t2
                new_name=['ASL ' datestr(t1)];
            else
                new_name=['ASL ' datestr(t1) ' to ' datestr(t2)];
            end
            
        otherwise
            if ~isempty(layers(ilay).get_survey_data())
                tmp=cell(1,numel(layers(ilay).SurveyData));
                for isdata=1:numel(layers(ilay).SurveyData)
                    temp_str=layers(ilay).get_survey_data('Idx',isdata).print_survey_data();
                    if~any(strcmpi(temp_str,tmp))
                        tmp{isdata}=layers(ilay).get_survey_data('Idx',isdata).print_survey_data();
                    end
                end
                tmp(cellfun(@isempty,tmp))=[];
                if ~isempty(tmp)
                    new_name=strjoin(tmp);
                else
                    new_name='';
                end
            else
                new_name=survey_data_cl().print_survey_data();
            end
            if strcmp(deblank(new_name),'')
                [~,files_lay]=layers(ilay).get_path_files();
               if numel(files_lay)>1
                   new_name=[files_lay{1} '...' files_lay{end}];
               else
                   new_name=files_lay{1} ;
               end
            end
    end
       
    u=1;
    new_name_ori=new_name;
    while nansum(strcmp(new_name,layers_Str))>=1
        new_name=[new_name_ori '_' num2str(u)];
        u=u+1;
    end
    if isempty(nb_char)||nb_char>length(new_name)
        layers_Str{ilay}=new_name;
    else
        layers_Str{ilay}=[new_name(1:nb_char) '...'];
    end
    
end