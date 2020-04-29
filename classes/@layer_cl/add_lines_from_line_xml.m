function pres=add_lines_from_line_xml(layers_obj,varargin)

p = inputParser;

addRequired(p,'layers_obj',@(obj) isa(obj,'layer_cl'));

parse(p,layers_obj,varargin{:});


for ilay=1:numel(layers_obj)
    try
        layer_obj=layers_obj(ilay);
        [path_xml,line_file_str]=layer_obj.create_files_line_str();
        
        pres=ones(length(line_file_str));
        
        for ix=1:length(line_file_str)
            xml_file=fullfile(path_xml{ix},line_file_str{ix});
            if exist(xml_file,'file')==0
                pres(ix)=0;
                continue;
            end
            
            [line_xml_tot,ver]=parse_line_xml(xml_file);
            
            if isempty(line_xml_tot)
                pres(ix)=0;
                fprintf('Cannot parse line for %s\n',layer_obj.Filename{ix});
                continue;
            end
            
            for iline=1:length(line_xml_tot)
                
                
                line_xml=line_xml_tot{iline};
                switch ver
                    case '0.1'
                        line=line_cl();
                        line.Tag=line_xml.att.tag;
                        line.Time=line_xml.line.time;
                        line.Type=line_xml.att.type;
                        line.UTC_diff=line_xml.att.utc_diff;
                        line.Dist_diff=line_xml.att.dist_diff;
                        line.File_origin={line_xml.att.file_origin};
                        line.Dr=line_xml.att.dr;
                        line.Range=line_xml.line.range;
                        if isnumeric(line_xml.att.id)
                            id=num2str(line_xml.att.id);
                        else
                            id=line_xml.att.id;
                        end
                        line.ID=id;
                        
                end
                layer_obj.add_lines(line);
                if strcmpi(line.Tag,'offset')
                    disp('Using Line as transducer offset');
                    for i=1:length(layer_obj.Transceivers)
                        layer_obj.Transceivers(i).set_transducer_depth_from_line(line);
                    end
                end
            end
        end
        
    catch err
        disp_perso(main_figure,err.message);
        laystr=list_layers(layer_obj,'nb_char',80);
        disp_perso([],sprintf('Could not load lines for layer %s',laystr{1}));
    end
end
end



