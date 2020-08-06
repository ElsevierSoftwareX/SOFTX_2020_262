
classdef gps_data_cl
    properties
        Lat =[];
        Long =[];
        Time =[];
        Dist =[];
        Speed= [];
        NMEA ='';
    end
    
    methods
        function obj = gps_data_cl(varargin)
            p = inputParser;
            
            addParameter(p,'Lat',[],@isnumeric);
            addParameter(p,'Long',[],@isnumeric);
            addParameter(p,'Time',[],@isnumeric);
            addParameter(p,'NMEA','',@ischar);
            parse(p,varargin{:});
            
            if ~isempty(p.Results.Lat)
                results=p.Results;
                props=fieldnames(results);
                
                for i=1:length(props)
                    if isprop(obj,props{i})
                        if isrow(results.(props{i}))
                            obj.(props{i})=results.(props{i});
                        else
                            obj.(props{i})=results.(props{i})';
                        end
                    end
                end
                obj.NMEA=obj.NMEA(:)';
                
                obj.Long(obj.Long<0)=obj.Long(obj.Long<0)+360;
                idx_nan=find((isnan(obj.Lat)+isnan(obj.Long))>0|(obj.Lat==0)|...
                    obj.Lat>90|obj.Lat<-90|obj.Long<0|obj.Long>360);
                
                obj.Long(idx_nan)=nan;
                obj.Lat(idx_nan)=nan;
                
                [~,idx_sort]=sort(obj.Time);
                
                obj.Long=obj.Long(idx_sort);
                obj.Lat=obj.Lat(idx_sort);
                obj.Time=obj.Time(idx_sort);
                
                if numel(obj.Long)>=2       
                    d_dist=lat_long_to_km(obj.Lat,obj.Long);                   
                    d_dist(isnan(d_dist))=0;
                    
                    dist_disp=[0 cumsum(d_dist)]*1000;%In meters!!!!!!!!!!!!!!!!!!!!!
                    
                    obj.Dist=dist_disp;
                else
                    obj.Dist=zeros(size(obj.Lat));
                end
                
            else
                nb_pings=length(p.Results.Time);
                obj.Long=zeros(1,nb_pings);
                obj.Lat=zeros(1,nb_pings);
                obj.Time=p.Results.Time;
                obj.Dist=zeros(1,nb_pings);
                obj.NMEA='';
            end            
        end
        
        
        function gps_data_out=concatenate_GPSData(gps_data_1,gps_data_2)
            
            if isempty(gps_data_1)&&isempty(gps_data_2)
                gps_data_out=gps_data_cl.empty();
                return;
            end
            
            if isempty(gps_data_1)
                gps_data_out=gps_data_2;
                return;
            end
            
            if isempty(gps_data_2)
                gps_data_out=gps_data_1;
                return;
            end
            
            Long_tot=[gps_data_1.Long gps_data_2.Long];
            Lat_tot=[gps_data_1.Lat gps_data_2.Lat];
            Time_tot=[gps_data_1.Time gps_data_2.Time];
            [Time_tot_s,idx_sort]=sort(Time_tot);
            Lat_tot_s=Lat_tot(idx_sort);
            Long_tot_s=Long_tot(idx_sort);
            
            gps_data_out=gps_data_cl('Lat',Lat_tot_s,...
                'Long',Long_tot_s,...
                'Time',Time_tot_s,...
                'NMEA',gps_data_1.NMEA);
        end
        
        function [obj_out,id_keep]=clean_gps_track(obj,varargin)
            if isempty(obj)
                obj_out=obj;
                id_keep=[];
                return;
            end
            if isempty(obj.Long)
                obj_out=obj;
                id_keep=[];
                return;
            end
            if isempty(varargin)
                prec=1e-6*2;
            else
                prec=varargin{1};
            end
            id_nn = find(~isnan(obj.Long));
            if numel(id_nn)<2
                obj_out=obj;
                id_keep =  1:numel(obj.Long);
                return;
            end
            
            [~,~,id_keep]=DouglasPeucker(obj.Long(id_nn),obj.Lat(id_nn),prec,0,1e3,0);
            
%             figure();
%             geoplot(obj.Lat(id_keep),obj.Long(id_keep),'-xr');hold on;
%             geoplot(obj.Lat,obj.Long,'k');
            id_keep = unique([1 id_keep(:)' numel(obj.Lat)]);
            id_keep = id_nn(id_keep);
            
            obj_out=gps_data_cl('Lat',obj.Lat(id_keep),'Long',obj.Long(id_keep),'Time',obj.Time(id_keep),'NMEA',obj.NMEA);
        end
        
        %% export GPS data to geostruct format
        function geostruct = gps_to_geostruct(obj,idx_pings)
            
            if isempty(idx_pings)
                idx_pings = 1:length(obj.Lat);
            end
            geostruct.Geometry    = 'Line';
            geostruct.BoundingBox = [[min(obj.Long(idx_pings)) min(obj.Lat(idx_pings))];[max(obj.Long(idx_pings)) max(obj.Lat(idx_pings))]];
            geostruct.Lat         = obj.Lat(idx_pings);
            geostruct.Lon         = obj.Long(idx_pings);
            geostruct.Date        = datestr(nanmean(obj.Time(idx_pings))); 
        end
        
        %% export GPS data to a .csv file
        function save_gps_to_file(obj,output_file,idx_pings)
            
            if isempty(idx_pings)
                idx_pings = 1:length(obj.Lat);
            end
            idx_pings = intersect(idx_pings,find(~isnan(obj.Time)&~isnan(obj.Lat)&~isnan(obj.Long)));
            
            struct_obj.Lat  = obj.Lat(idx_pings)';
            struct_obj.Long = obj.Long(idx_pings)';
            struct_obj.Time = cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS'),(num2cell(obj.Time(idx_pings))'),'UniformOutput',0);
            
            struct2csv(struct_obj,output_file);
            
        end
        
        %%
        function gps_data_section=get_GPSDData_time_section(gps_data_obj,ts,te)
            gps_data_section=gps_data_obj;
            idx_rem=gps_data_obj.Time<ts|gps_data_obj.Time>te;
            gps_data_section.Time(idx_rem)=[];
            gps_data_section.Lat(idx_rem)=[];
            gps_data_section.Long(idx_rem)=[];
            gps_data_section.Dist(idx_rem)=[];
        end
        
        function gps_data_section=get_GPSDData_idx_section(gps_data_obj,idx)
            idx(idx<=0|idx>numel(gps_data_obj.Time))=[];
            gps_data_section=gps_data_obj;
            
            gps_data_section.Time=gps_data_obj.Time(idx);
            gps_data_section.Lat=gps_data_obj.Lat(idx);
            gps_data_section.Long=gps_data_obj.Long(idx);
            gps_data_section.Dist=gps_data_obj.Dist(idx);
        end
        
        
        
        
    end
    methods(Static)
        
        
        function obj=load_gps_from_file(fileN)
            
            if ~iscell(fileN)
                fileN={fileN};
                
            end
            
            for ifi=1:length(fileN)
                [~,~,ext]=fileparts(fileN{ifi});
                try
                    switch ext
                        case {'.csv','.txt'}
                            
                            opts = detectImportOptions(fileN{ifi});
                            opts = setvaropts(opts,'Time','InputFormat','dd/MM/uuuu HH:mm:ss'); 
                            temp=readtable(fileN{ifi},opts);
                            
                            fields =ismember({'Lat','Long','Time'},temp.Properties.VariableNames); 
                            fields_comp =ismember({'Lat','Long','Time','Date'},temp.Properties.VariableNames); 
                            
                            if all(fields_comp)
                                switch class(temp.Time)
                                    case 'duration'
                                         idx_keep=~isnan(temp.Time)|~isnat(temp.Date);
                                    case 'datetime'
                                        idx_keep=~isnat(temp.Time)|~isnat(temp.Date);
                                end
                                obj_temp=gps_data_cl('Lat',temp.Lat(idx_keep),'Long',temp.Long(idx_keep),'Time',datenum(temp.Time(idx_keep))+datenum(temp.Date(idx_keep)));
                            elseif all(fields)
                                idx_keep=~isnat(temp.Time);
                                switch class(temp.Time)
                                    case 'duration'
                                        idx_keep=~isnatn(temp.Time);
                                    case 'datetime'
                                        idx_keep=~isnat(temp.Time);
                                end
                                obj_temp=gps_data_cl('Lat',temp.Lat(idx_keep),'Long',temp.Long(idx_keep),'Time',datenum(temp.Time(idx_keep)));
                            else
                                obj_temp=gps_data_cl.empty();
                            end
                            
                        case '.mat'
                            
                            gps_data=load(fileN{ifi});
                            fields = isfield(gps_data,{'Lat','Long','Time'});
                            if all(fields)
                                obj_temp=gps_data_cl('Lat',gps_data.Lat,'Long',gps_data.Long,'Time',gps_data.Time);
                            else
                                obj_temp=gps_data_cl.empty();
                            end
                            
                            
                    end
                    
                catch
                    fprintf('Could not read gps file %s\n',fileN{ifi});
                    obj_temp=gps_data_cl.empty();
                    
                end
                
                obj_temp=obj_temp.clean_gps_track();
                
                if ifi>1
                    obj=concatenate_GPSData(obj,obj_temp);
                else
                    obj=obj_temp;
                end
            end
        end
        
        
     
        function delete(obj)
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
        
    end
end
