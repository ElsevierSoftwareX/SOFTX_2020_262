function obj=map_input_cl_from_obj(Ext_obj,varargin)

p = inputParser;
check_layer_cl=@(x) isempty(x)|isa(x,'layer_cl')|isa(x,'mbs_cl')|isa(x,'survey_cl')|isa(x,'gps_data_cl')|isstruct(x);
addRequired(p,'Ext_obj',check_layer_cl);

addParameter(p,'ValMax',0.0001,@isnumeric);
addParameter(p,'Rmax',2,@isnumeric);
addParameter(p,'SliceSize',100,@isnumeric);
addParameter(p,'Freq',38000,@isnumeric);
addParameter(p,'Basemap','landcover',@ischar);
addParameter(p,'Depth_Contour',0,@isnumeric);

parse(p,Ext_obj,varargin{:});
obj=map_input_cl();

switch class(Ext_obj)
    case 'layer_cl'
        layers=Ext_obj;
        nb_trans=length(layers);
    case 'mbs_cl'
        mbs=Ext_obj;
        mbs_out=mbs.Output.slicedTransectSum.Data;
        mbs_out_reg=mbs.Output.regionSum.Data;
        mbs_head=mbs.Header;
        nb_trans=size(mbs_out,1);
    case 'survey_cl'
        survey_obj=Ext_obj;
        
        if isempty(survey_obj.SurvOutput)
            obj=[];
            return;
        end
        nb_trans=length(survey_obj.SurvOutput.transectSum.snapshot);
    case {'struct' 'gps_data_cl'}
        nb_trans=1;
    otherwise
        return;
end


obj.Title=cell(1,nb_trans);
obj.Title(:)='';
obj.SurveyName=cell(1,nb_trans);
obj.SurveyName(:)='';
obj.Voyage=cell(1,nb_trans);
obj.Voyage(:)='';
obj.Filename=cell(1,nb_trans);
obj.Snapshot=zeros(1,nb_trans);
obj.Stratum=cell(1,nb_trans);
obj.Transect=zeros(1,nb_trans);
obj.Lat=cell(1,nb_trans);
obj.Long=cell(1,nb_trans);
obj.Time=cell(1,nb_trans);
obj.SliceLat=cell(1,nb_trans);
obj.SliceLong=cell(1,nb_trans);
obj.SliceTime_S=cell(1,nb_trans);
obj.SliceTime_E=cell(1,nb_trans);
obj.SliceAbscf=cell(1,nb_trans);
obj.Nb_ST=cell(1,nb_trans);
obj.Nb_Tracks=cell(1,nb_trans);
obj.ValMax=p.Results.ValMax;
obj.Rmax=p.Results.Rmax;
obj.Basemap=p.Results.Basemap;
obj.Depth_Contour=p.Results.Depth_Contour;
obj.StationCode=cell(1,nb_trans);

obj.LatLim=[nan nan];
obj.LongLim=[nan nan];

switch class(Ext_obj)
    case 'mbs_cl'
        for i=1:nb_trans
            if ~strcmpi(mbs_head.voyage,'')
                obj.Voyage{i}=mbs_head.voyage;
            else
                obj.Voyage{i}=mbs_head.title;
            end
            obj.Title=mbs_head.title;
            obj.SurveyName{i}=mbs_head.title;
            obj.SliceLat{i}=mbs_out{i,6};
            obj.SliceLong{i}=mbs_out{i,7};
            obj.SliceLong{i}(obj.SliceLong{i}<0)=obj.SliceLong{i}(obj.SliceLong{i}<0)+360;
            obj.SliceAbscf{i}=mbs_out{i,8};
            obj.Snapshot(i)=mbs_out{i,1};
            obj.Stratum{i}=mbs_out{i,2};
            obj.Transect(i)=mbs_out{i,3};
            obj.LatLim(1)=nanmin(obj.LatLim(1),nanmin(obj.SliceLat{i}));
            obj.LongLim(1)=nanmin(obj.LongLim(1),nanmin(obj.SliceLong{i}));
            obj.LatLim(2)=nanmax(obj.LatLim(2),nanmax(obj.SliceLat{i}));
            obj.LongLim(2)=nanmax(obj.LongLim(2),nanmax(obj.SliceLong{i}));
            
            idx_file=find(obj.Snapshot(i)==[mbs_out_reg{:,1}]...
                &strcmpi(obj.Stratum{i},{mbs_out_reg{:,2}})...
                &obj.Transect(i)==[mbs_out_reg{:,3}],1);
            if ~isempty(idx_file)
                obj.Filename{i}=mbs_out_reg{idx_file,4};
            end
        end
        
    case 'layer_cl'
        for i=1:nb_trans
            obj.Filename{i}=layers(i).Filename;
            obj.Lat{i}=layers(i).GPSData.Lat;
            obj.Long{i}=layers(i).GPSData.Long;
            obj.Time{i}=layers(i).GPSData.Time;
            if ~isempty(layers(i).get_survey_data())
                surv_data=layers(i).get_survey_data();
                obj.Voyage{i}=surv_data.Voyage;
                obj.Snapshot(i)=surv_data.Snapshot;
                obj.Stratum{i}=surv_data.Stratum;
                obj.Transect(i)=surv_data.Transect;
                obj.SurveyName{i}=surv_data.SurveyName;
            else
                obj.Voyage{i}='';
                obj.SurveyName{i}='';
            end
            
            [trans_obj,~]=layers(i).get_trans(p.Results.Freq);
            
            if isempty(trans_obj)
                continue;
            end
            if isempty(trans_obj.Data)
                continue;
            end
            
            if p.Results.SliceSize>0
                idx_reg=1:length(trans_obj.Regions);
                idx_bad=zeros(1,length(idx_reg));

                for ireg=1:length(idx_reg)
                    if strcmpi(trans_obj.Regions(ireg).Type,'Bad Data')
                        idx_bad(ireg)=1;
                    end
                end
                
                idx_reg(idx_bad==1)=[];
                [output_2D,output_type,~,~,~]=trans_obj.slice_transect2D_new_int('Idx_reg',idx_reg,...
                    'survey_options',survey_options_cl('Options',struct('Vertical_slice_size',p.Results.SliceSize,'Vertical_slice_units','pings')));
                     
                slice_int=[];
                good_pings=0;
                
                for itout=1:numel(output_type)
                    if ~isempty(slice_int)
                        slice_int=slice_int+nansum(output_2D{itout}.eint);
                    else
                        slice_int=nansum(output_2D{itout}.eint);
                    end
                    good_pings=nanmax(good_pings,nanmax(output_2D{itout}.Nb_good_pings,[],1));
                end
                
                if good_pings==0
                    continue;
                else
                
                obj.SliceLat{i}=1/2*(output_2D{1}.Lat_S+output_2D{1}.Lat_E);
                obj.SliceLong{i}=1/2*(output_2D{1}.Lon_S+output_2D{1}.Lon_E);
                obj.SliceLong{i}(obj.SliceLong{i}<0)=obj.SliceLong{i}(obj.SliceLong{i}<0)+360;
                obj.SliceAbscf{i}=((slice_int)./good_pings);
                obj.SliceAbscf{i}(isnan(obj.SliceAbscf{i}))=0;
                
                obj.SliceTime_S{i}=output_2D{1}.Time_S;
                obj.SliceTime_E{i}=output_2D{1}.Time_E;
                end
            end
        end
        
        for it=1:nb_trans
            if ~isempty(obj.Lat{it})
                obj.LatLim(1)=nanmin(obj.LatLim(1),nanmin(obj.Lat{it}));
                obj.LongLim(1)=nanmin(obj.LongLim(1),nanmin(obj.Long{it}));
                obj.LatLim(2)=nanmax(obj.LatLim(2),nanmax(obj.Lat{it}));
                obj.LongLim(2)=nanmax(obj.LongLim(2),nanmax(obj.Long{it}));
            end
        end
        
    case 'survey_cl'
        
        for i=1:nb_trans
            if ~strcmpi(survey_obj.SurvInput.Infos.Voyage,'')
                obj.Voyage{i}=survey_obj.SurvInput.Infos.Voyage;
            else
                obj.Voyage{i}=survey_obj.SurvInput.Infos.Title;
            end
            obj.Title{i}=survey_obj.SurvInput.Infos.Title;
            obj.SurveyName{i}=survey_obj.SurvInput.Infos.SurveyName;
            obj.SliceLat{i}=survey_obj.SurvOutput.slicedTransectSum.latitude{i};
            obj.SliceLong{i}=survey_obj.SurvOutput.slicedTransectSum.longitude{i};
            obj.SliceLong{i}(obj.SliceLong{i}<0)=obj.SliceLong{i}(obj.SliceLong{i}<0)+360;
            obj.SliceTime_S{i}=survey_obj.SurvOutput.slicedTransectSum.time_start{i};
            obj.SliceTime_E{i}=survey_obj.SurvOutput.slicedTransectSum.time_end{i};
            obj.SliceAbscf{i}=survey_obj.SurvOutput.slicedTransectSum.slice_abscf{i};
            obj.Nb_ST{i}=survey_obj.SurvOutput.slicedTransectSum.slice_nb_st{i};
            obj.Nb_Tracks{i}=survey_obj.SurvOutput.slicedTransectSum.slice_nb_tracks{i};
            obj.Snapshot(i)=survey_obj.SurvOutput.slicedTransectSum.snapshot(i);
            obj.Stratum{i}=survey_obj.SurvOutput.slicedTransectSum.stratum{i};
            obj.Transect(i)=survey_obj.SurvOutput.slicedTransectSum.transect(i);
            obj.LatLim(1)=nanmin(obj.LatLim(1),nanmin(obj.SliceLat{i}));
            obj.LongLim(1)=nanmin(obj.LongLim(1),nanmin(obj.SliceLong{i}));
            obj.LatLim(2)=nanmax(obj.LatLim(2),nanmax(obj.SliceLat{i}));    
            obj.LongLim(2)=nanmax(obj.LongLim(2),nanmax(obj.SliceLong{i}));
            idx_file=find(obj.Snapshot(i)==survey_obj.SurvOutput.regionSum.snapshot...
                &strcmpi(obj.Stratum(i),survey_obj.SurvOutput.regionSum.stratum)...
                &obj.Transect(i)==survey_obj.SurvOutput.regionSum.transect,1);
            
            if ~isempty(idx_file)
                obj.Filename{i}=survey_obj.SurvOutput.regionSum.file{idx_file};
            else
                obj.Filename{i}={''};
            end
            
        end
        
        for ireg=1:length(survey_obj.SurvOutput.regionSum.tag)
            obj.Regions.Tag{ireg}=survey_obj.SurvOutput.regionSum.tag{ireg};
            obj.Regions.abscf(ireg)=survey_obj.SurvOutput.regionSum.abscf(ireg);
            obj.Regions.Snapshot(ireg)=survey_obj.SurvOutput.regionSum.snapshot(ireg);
            obj.Regions.Stratum{ireg}=survey_obj.SurvOutput.regionSum.stratum(ireg);
            obj.Regions.Transect(ireg)=survey_obj.SurvOutput.regionSum.transect(ireg);
            obj.Regions.Lat_m(ireg)=nanmean(survey_obj.SurvOutput.regionSumAbscf.latitude{ireg});
            obj.Regions.Long_m(ireg)=nanmean(survey_obj.SurvOutput.regionSumAbscf.longitude{ireg});
        end
    case {'struct' 'gps_data_cl'}
        fields=fieldnames(Ext_obj);
        
        for ifi=1:length(fields)
            if isprop(obj,fields{ifi})
                if iscell(obj.(fields{ifi}))&&~iscell(Ext_obj.(fields{ifi}))
                    obj.(fields{ifi})={Ext_obj.(fields{ifi})};
                else
                    obj.(fields{ifi})=Ext_obj.(fields{ifi});
                end
            end
        end
        lat_lim=[nan nan];
        lon_lim=[nan nan];
        
        if iscell(obj.Lat)
            lat=[obj.Lat{:}];
        else
            lat=obj.Lat;
        end
        
        if iscell(obj.Long)
            long=[obj.Long{:}];
        else
            long=obj.Long;
        end
        lat(lat==0|long==0)=nan;
        long(isnan(lat))=nan;
        
        lat_lim(1)=nanmin(lat_lim(1),nanmin(lat));
        lon_lim(1)=nanmin(lon_lim(1),nanmin(long));
        lat_lim(2)=nanmax(lat_lim(2),nanmax(lat));
        lon_lim(2)=nanmax(lon_lim(2),nanmax(long));
        [lat_lim,lon_lim]=ext_lat_lon_lim_v2(lat_lim,lon_lim,0.1);
        obj.LatLim=lat_lim;
        obj.LongLim=lon_lim;
end

end