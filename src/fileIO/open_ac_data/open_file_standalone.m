function [new_layers,multi_lay_mode]=open_file_standalone(Filename,ftype,varargin)

p = inputParser;

if ~iscell(Filename)
    Filename={Filename};
end

[def_path_m,~,~]=fileparts(Filename{1});

addRequired(p,'Filename',@(x) ischar(x)||iscell(x));
addRequired(p,'ftype',@(x) ischar(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'already_opened_files',{},@iscell);
addParameter(p,'dfile',0,@isnumeric);
addParameter(p,'CVSCheck',0);
addParameter(p,'CVSroot','');
addParameter(p,'SvCorr',1);
addParameter(p,'Calibration',[]);
addParameter(p,'EnvData',[]);
addParameter(p,'absorption',[]);
addParameter(p,'absorption_f',[]);
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
addParameter(p,'FieldNames',{});
addParameter(p,'EsOffset',[]);
addParameter(p,'GPSOnly',0);
addParameter(p,'LoadEKbot',0);
addParameter(p,'force_open',0);
addParameter(p,'sub_sample',1);
addParameter(p,'bot_ver',-1);
addParameter(p,'reg_ver',-1);

new_layers=[];
multi_lay_mode=0;

parse(p,Filename,ftype,varargin{:});

if isempty(ftype)
    ftype_cell = cellfun(@get_ftype,Filename,'un',0);
else
    ftype_cell=cell(1,numel(Filename));
    ftype_cell(:)={ftype};
end

ftype_cell_unique=unique(ftype_cell);

for iftype=1:numel(ftype_cell_unique)
    try
        new_layers_tmp=[];
        Filename_tmp=Filename(strcmp(ftype_cell,ftype_cell_unique{iftype}));
        ftype=ftype_cell_unique{iftype};
        
        
        switch ftype
            case 'FCV30'
                for ifi = 1:length(Filename_tmp)
                    if ~isempty(p.Results.load_bar_comp)
                        str_disp=sprintf('Opening File %d/%d : %s',ifi,length(Filename_tmp),Filename_tmp{ifi});
                        p.Results.load_bar_comp.progress_bar.setText(str_disp);
                    end
                    
                    lays_tmp=open_FCV30_file(Filename_tmp{ifi},...
                        'already_opened_files',p.Results.already_opened_files,...
                        'PathToMemmap',p.Results.PathToMemmap,...
                        'load_bar_comp',p.Results.load_bar_comp);
                    
                    new_layers_tmp=[new_layers_tmp lays_tmp];
                    if ~isempty(p.Results.load_bar_comp)
                        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename_tmp),'Value',ifi);
                    end
                end
                multi_lay_mode=0;
                
            case {'EK60','EK80'}
                new_layers_tmp=open_EK_file_stdalone(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'LoadEKbot',p.Results.LoadEKbot,...
                    'load_bar_comp',p.Results.load_bar_comp,...
                    'EsOffset',p.Results.EsOffset,...
                    'Frequencies',p.Results.Frequencies,...
                    'Channels',p.Results.Channels,...
                    'GPSOnly',p.Results.GPSOnly,...
                    'FieldNames',p.Results.FieldNames,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'load_bar_comp',p.Results.load_bar_comp,...
                    'force_open',p.Results.force_open,...
                    'sub_sample',p.Results.sub_sample);
                multi_lay_mode=0;
            case 'ASL'
                
                new_layers_tmp=open_asl_files(Filename_tmp,...
                    'already_opened_files',p.Results.already_opened_files,...
                    'PathToMemmap',p.Results.PathToMemmap,...
                    'Frequencies',p.Results.Frequencies,...
                    'load_bar_comp',p.Results.load_bar_comp,...
                    'force_open',p.Results.force_open);
                multi_lay_mode=0;
                
            case 'TOPAS'
                new_layers_tmp=open_topas_files(Filename_tmp,...
                    'PathToMemmap',p.Results.PathToMemmap,'load_bar_comp',p.Results.load_bar_comp);
                multi_lay_mode=0;
            case 'CREST'
                switch p.Results.dfile
                    case 1
                        new_layers_tmp=read_crest(Filename_tmp,...
                            'PathToMemmap',p.Results.PathToMemmap,'CVSCheck',p.Results.CVSCheck,'CVSroot',p.Results.CVSroot,'SvCorr',p.Results.SvCorr);
                    case 0
                        new_layers_tmp=open_dfile(Filename_tmp,'CVSCheck',p.Results.CVSCheck,'CVSroot',p.Results.CVSroot,...
                            'PathToMemmap',p.Results.PathToMemmap,'load_bar_comp',p.Results.load_bar_comp,'EsOffset',p.Results.EsOffset);
                end
                multi_lay_mode=0;
                
            case {'Unknown' 'db'}
                for ifi=1:length(Filename_tmp)
                    fprintf('Could not open %s\n',Filename_tmp{ifi});
                end
            otherwise
                for ifi=1:length(Filename_tmp)
                    fprintf('Unrecognized File type for Filename %s\n',Filename_tmp{ifi});
                end
        end
        
        if isempty(new_layers_tmp)
            return;
        end
        
        if ~isempty(p.Results.load_bar_comp)
            p.Results.load_bar_comp.progress_bar.setText('Loading Survey Metadata');
        end
        
        new_layers_tmp.load_echo_logbook_db();
        new_layers_tmp.add_lines_from_line_xml();
        new_layers_tmp.create_survey_options_xml([]);
        
        new_layers_tmp_sorted=new_layers_tmp.sort_per_survey_data();
        
        new_layers_tmp_tot=[];
        
        for icell=1:length(new_layers_tmp_sorted)
            new_layers_tmp_tot=[new_layers_tmp_tot shuffle_layers(new_layers_tmp_sorted{icell},'multi_layer',multi_lay_mode)];
        end
        
        if ~isempty(p.Results.load_bar_comp)
            p.Results.load_bar_comp.progress_bar.setText('Computing Sv and Sp');
            
            p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',numel(new_layers_tmp_tot),'Value',0);
        end
        
        
        for uil=1:numel(new_layers_tmp_tot)
            
            if p.Results.GPSOnly==0
                
                
                nb_trans = numel(new_layers_tmp_tot(uil).Transceivers);
                
                for uit = 1:nb_trans
                    new_layers_tmp_tot(uil).Transceivers(uit).Params = new_layers_tmp_tot(uil).Transceivers(uit).Params.reduce_params();    
                end
                
                if ~isempty(p.Results.EnvData)
                    new_layers_tmp_tot(uil).set_EnvData(p.Results.EnvData);
                    
                    if isempty(p.Results.EnvData.CTD.depth)&&strcmpi(p.Results.EnvData.CTD.ori,'profile')
                        new_layers_tmp_tot(uil).load_ctd('','profile');
                    end
                    
                    if isempty(p.Results.EnvData.SVP.depth)&&strcmpi(p.Results.EnvData.SVP.ori,'profile')
                        new_layers_tmp_tot(uil).load_svp('','profile');
                    end
                    
                else
                    survey_options_obj=new_layers_tmp_tot(uil).get_survey_options();
                    if ~isnan(survey_options_obj.Soundspeed)
                        new_layers_tmp_tot(uil).EnvData.SoundSpeed=survey_options_obj.Soundspeed;
                    end
                    for uit=1:numel(new_layers_tmp_tot(uil).Transceivers)
                       new_layers_tmp_tot(uil).Transceivers(uit).Config.EsOffset = survey_options_obj.Es60_correction;
                    end
                    
                    new_layers_tmp_tot(uil).load_svp('','constant');
                    new_layers_tmp_tot(uil).load_ctd('','constant');
                end
                
                
                
                new_layers_tmp_tot(uil).layer_computeSpSv('Calibration',p.Results.Calibration,...
                    'load_bar_comp',p.Results.load_bar_comp,...
                    'absorption_f',p.Results.absorption_f,...
                    'absorption',p.Results.absorption);
                
                
                algo_vec_init=init_algos();
                [~,~,algo_vec,~]=load_config_from_xml(0,0,1);
                
                new_layers_tmp_tot(uil).add_algo(algo_vec_init,'reset_range',true);
                new_layers_tmp_tot(uil).add_algo(algo_vec,'reset_range',true);
                
                
                new_layers_tmp_tot(uil).load_bot_regs('bot_ver',p.Results.bot_ver,'reg_ver',p.Results.reg_ver);
                
                new_layers_tmp_tot(uil).get_att_data_from_csv({},0);
                new_layers_tmp_tot(uil).get_gps_data_from_csv({},0);
                if ~isempty(p.Results.load_bar_comp)
                    p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',numel(new_layers_tmp_tot),'Value',uil);
                end
            end
                
        end
        
        if ~isempty(p.Results.load_bar_comp)
            p.Results.load_bar_comp.progress_bar.setText('Updating Database with GPS Data');
        end
        new_layers_tmp_tot.add_ping_data_to_db(1,0);
        
        new_layers=[new_layers new_layers_tmp_tot];
    catch err
        print_errors_and_warnings(1,'error',err);
    end
end