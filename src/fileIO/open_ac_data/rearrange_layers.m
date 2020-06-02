function layers_out=rearrange_layers(layers_in,multi_layer)

%multi_layer=-1: force concatenation of compatible layers
%multi_layer=0: concatenate only consecutive/compatible layers
%multi_layer=1: do nothing

if multi_layer==1
    layers_out=layers_in;
    return;
end

t_start=nan(1,numel(layers_in));
for i=1:numel(layers_in)
    [t_start(i),~]=layers_in(i).get_time_bounds();
end
[~,idx_sort]=sort(t_start);
layers_in=layers_in(idx_sort);


filetype=cell(1,length(layers_in));
cids=cell(1,length(layers_in));
nb_transceivers=nan(1,length(layers_in));
transceiver_combination=nan(1,length(layers_in));
transceiver_combination_cell={};

for i=1:length(layers_in)
    curr_layer=layers_in(i);
    cids{i}=curr_layer.ChannelID;
    idx=find(cellfun(@(x) all(ismember(cids{i},x))&&numel(cids{i})==numel(x),transceiver_combination_cell));
    
    if isempty(idx)
        transceiver_combination_cell{end+1}=cids{i};
        transceiver_combination(i)=numel(transceiver_combination_cell);
        
    else
        transceiver_combination(i)=idx;
    end
    
    nb_transceivers(i)=length(curr_layer.Transceivers);
    filetype{i}=curr_layer.Filetype;
    %fold_temp=curr_layer.get_folder();
    
end

[trans_comb,ia]=unique(transceiver_combination);

trans_nb=nb_transceivers(ia);

idx_to_concatenate=cell(1,length(trans_comb));
idx_not_to_concatenate=cell(1,length(trans_comb));


for uu=1:length(trans_comb)
    idx=find(transceiver_combination==trans_comb(uu));
    
    for jj=1:length(idx)
        curr_layer=layers_in(idx(jj));
        if (trans_nb(uu))>0
            for ii=1:trans_nb(uu)
                curr_trans=curr_layer.Transceivers(ii);
                layers_grp(uu).cid{ii,jj}=curr_trans.Config.ChannelID;
                layers_grp(uu).sample_interval(ii,jj)=ceil(curr_trans.get_params_value('SampleInterval',1)/eps)*eps;
                
                if ~isempty(curr_trans.get_transceiver_range())
                    layers_grp(uu).time_start(ii,jj)=curr_trans.Time(1);
                    layers_grp(uu).time_end(ii,jj)=curr_trans.Time(end);
                    layers_grp(uu).dt(ii,jj)=(curr_trans.Time(end)-curr_trans.Time(1))/length(curr_trans.Time);
                else
                    layers_grp(uu).time_start(ii,jj)=curr_trans.Time(1);
                    layers_grp(uu).time_end(ii,jj)=curr_trans.Time(end);
                    layers_grp(uu).dt(ii,jj)=5/(24*60*60);
                end
            end
        else
            layers_grp(uu).cid{1,jj}='';
            if~isempty(curr_layer.GPSData.Time)
                layers_grp(uu).time_start(1,jj)=curr_layer.GPSData.Time(1);
                layers_grp(uu).time_end(1,jj)=curr_layer.GPSData.Time(end);
                layers_grp(uu).dt(1,jj)=(curr_layer.GPSData.Time(end)-curr_layer.GPSData.Time(1))/length(curr_layer.GPSData.Time)*10;
            end
            layers_grp(uu).sample_interval(1,jj)=0;
        end
        
    end
    
    sample_int=unique(layers_grp(uu).sample_interval','rows')';
    
    idx_to_concatenate{uu}=cell(1,size(sample_int,2));
    idx_not_to_concatenate{uu}=[];
    for kk=1:size(sample_int,2)
        idx_to_concatenate{uu}{kk}=[];
        
        if trans_nb(uu)>0
            idx_same_sample_int=find(nansum(layers_grp(uu).sample_interval==repmat(sample_int(:,kk),1,size(layers_grp(uu).sample_interval,2)),1)==trans_nb(uu));
            %idx_same_sample_int=find(nansum(layers_grp(uu).sample_interval>0,1)==trans_nb(uu));
        else
             idx_same_sample_int=find(nansum(layers_grp(uu).sample_interval==repmat(sample_int(:,kk),1,size(layers_grp(uu).sample_interval,2)),1));
             %idx_same_sample_int=find(nansum(layers_grp(uu).sample_interval>0,1));
             trans_nb(uu)=1;
        end
        
        if multi_layer == 0
            for kki=idx_same_sample_int
                for kkj=idx_same_sample_int
                                        
                    first_cond= kki == kkj || nansum(layers_grp(uu).time_end(:,kki)==layers_grp(uu).time_end(:,kkj)|...
                        layers_grp(uu).time_start(:,kki)==layers_grp(uu).time_start(:,kkj)|...
                        (layers_grp(uu).time_start(:,kki)>=layers_grp(uu).time_start(:,kkj)&...
                        layers_grp(uu).time_start(:,kki)<=layers_grp(uu).time_end(:,kkj))|...
                        (layers_grp(uu).time_end(:,kki)>=layers_grp(uu).time_start(:,kkj)&...
                        layers_grp(uu).time_end(:,kki)<=layers_grp(uu).time_end(:,kkj)))...
                        ==trans_nb(uu);
                    
                    if first_cond
                        continue;
                    end
                                        
                    second_cond= nansum(layers_grp(uu).time_end(:,kki)+ 5*layers_grp(uu).dt(:,kki)>=layers_grp(uu).time_start(:,kkj)&...
                        layers_grp(uu).time_end(:,kki)-5*layers_grp(uu).dt(:,kki)<=layers_grp(uu).time_start(:,kkj))==trans_nb(uu);
                    
                    if second_cond
                        if all(ismember([idx(kkj) idx(kki)],idx_to_concatenate{uu}{kk}))
                            continue;
                        end
                        idx_to_concatenate{uu}{kk}=[idx_to_concatenate{uu}{kk}; [idx(kki) idx(kkj)]];
                    end
                    
                end
            end
        else
            [~,idx_sort]=sort(layers_grp(uu).time_start(1,idx_same_sample_int));
            if length(idx_sort)>=2
                idx_to_concatenate{uu}{kk}=[idx(idx_same_sample_int(idx_sort(1:end-1)));idx(idx_same_sample_int(idx_sort(2:end)))]';
            else
                idx_to_concatenate{uu}{kk}=[];
            end
        end
        
        if ~isempty(idx_to_concatenate{uu}{kk})
            new_not_to=setdiff(idx(idx_same_sample_int),unique(idx_to_concatenate{uu}{kk}(:)));
            idx_not_to_concatenate{uu}=unique([idx_not_to_concatenate{uu}(:);new_not_to(:)]);
        else
            new_to=idx(idx_same_sample_int(:));
            idx_not_to_concatenate{uu}=unique([idx_not_to_concatenate{uu}(:) ; new_to(:)]);
        end
    end
end

layers_out=[];

for uui=1:length(idx_to_concatenate)
    errored_layers=[];
    for kki=1:length(idx_to_concatenate{uui})
        couples=idx_to_concatenate{uui}{kki};
        if isempty(couples)
            continue;
        end
        if multi_layer>-1
            idx_looked=[];
            new_chains={};
            new_chains_start=[];
            new_chains_end=[];
            kkki=1;
            
            while length(idx_looked)<size(couples,1)
                [chains_start,chains_end,chains,idx_looked]=get_chains(couples,[],[],{},idx_looked);
                new_chains={new_chains{:} chains{:}};
                new_chains_start=[new_chains_start chains_start];
                new_chains_end=[new_chains_end chains_end];
                kkki=kkki+1;
            end
            
            for i=1:length(new_chains)
                for j=1:length(new_chains)
                    if ~isempty(intersect(new_chains{i},new_chains{j}))&&(j~=i)
                        time_i=layers_in(new_chains{i}(end)).Transceivers(1).Time(end)-layers_in(new_chains{i}(1)).Transceivers(1).Time(1);
                        time_j=layers_in(new_chains{j}(end)).Transceivers(1).Time(end)-layers_in(new_chains{j}(1)).Transceivers(1).Time(1);
                        
                        if time_j>=time_i
                            temp_u=setdiff(new_chains{i},new_chains{j});
                            new_chains{i}=[];
                        else
                            temp_u=setdiff(new_chains{j},new_chains{i});
                            new_chains{j}=[];
                        end
                        idx_not_to_concatenate{uui}=unique([idx_not_to_concatenate{uui}(:); temp_u(:)]);
                    end
                end
            end
        else
            if ~isempty(couples)
                new_chains{1}=[couples(:,1) ;couples(end,end)];
            else
                new_chains{1}=[];
            end
        end
        
        for iik=1:length(new_chains)
            curr_layers=layers_in(new_chains{iik});
            
            if length(curr_layers)>1
                layer_conc=curr_layers(1);
                for kk=1:length(curr_layers)-1
                    if ~isempty(layer_conc.Transceivers)
                        t_1=layer_conc.Transceivers(1).Time(end);
                    elseif ~isempty(layer_conc.GPSData.Time)
                        t_1=layer_conc.GPSData.Time(end);
                    else
                       t_1=[]; 
                    end
                    
                    if ~isempty(curr_layers(kk+1).Transceivers)
                        t_2=curr_layers(kk+1).Transceivers(1).Time(end);
                    elseif ~isempty(curr_layers(kk+1).GPSData.Time)
                        t_2=curr_layers(kk+1).GPSData.Time(end);
                    else
                        t_2=[];
                    end
                    try
                        if t_1<=t_2
                            layer_conc=concatenate_layers(layer_conc,curr_layers(kk+1));
                        else
                            layer_conc=concatenate_layers(curr_layers(kk+1),layer_conc);
                        end
                    catch err
                        print_errors_and_warnings([],'error',err);
                        errored_layers=[errored_layers curr_layers(kk+1)] ;
                    end
                    
                end
                clear curr_layers;
                layers_out=[layers_out layer_conc];
            end
        end
    end
    layers_out=[layers_out errored_layers];
    for kkkj=1:length(idx_not_to_concatenate{uui})
        layers_out=[layers_out layers_in(idx_not_to_concatenate{uui}(kkkj))];
    end
      
end