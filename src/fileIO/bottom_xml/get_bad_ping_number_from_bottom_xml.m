function [nb_bad_pings,nb_pings,files_out,freq_vec,cids]=get_bad_ping_number_from_bottom_xml(files)

if ~iscell(files)
    files={files};
end

nb_pings_t=[];
nb_bad_pings_t=[];
freq_vec_t=[];
files_out_t={};
ChannelID_cell_t={};
for i_file=1:length(files)
    
    file_curr=files{i_file};
    [path_f,fileTemp,~]=fileparts(file_curr);
    
    bot_file_curr=fullfile(path_f,'bot_reg',['b_' fileTemp '.xml']);
    if exist(bot_file_curr,'file')==0
        continue;
    end
    bottom_xml=parse_bottom_xml(bot_file_curr);
        
    fileIdx=fullfile(path_f,'echoanalysisfiles',[fileTemp '_echoidx.mat']);
    if isfile(fileIdx)
        load(fileIdx);
        nb_pings_f=nansum(contains(idx_raw_obj.type_dg,{'RAW3' 'RAW0'}))/numel(unique(idx_raw_obj.chan_dg(~isnan(idx_raw_obj.chan_dg))));
    else
        nb_pings_f=[];
    end
    
    
    if ~isempty(bottom_xml)
        for ibot=1:length(bottom_xml)
            if isfield(bottom_xml{ibot}.Infos,'NbPings')
                nb_pings_t=[nb_pings_t bottom_xml{ibot}.Infos.NbPings];
            elseif ~isempty(nb_ping_f)
                nb_pings_t=[nb_pings_t nb_pings_f];
            else
                continue;
            end
            if isfield(bottom_xml{ibot}.Infos,'NbPings')
                ChannelID_cell_t=[ChannelID_cell_t bottom_xml{ibot}.Infos.ChannelID];
            else
                ChannelID_cell_t=[ChannelID_cell_t num2str(bottom_xml{ibot}.Infos.Freq)];
            end
            freq_vec_t=[freq_vec_t bottom_xml{ibot}.Infos.Freq];
            nb_bad_pings_t=[nb_bad_pings_t nansum(bottom_xml{ibot}.Bottom.Tag==0)];
            files_out_t=[files_out_t fileTemp];
        end
    end
end

[cids,idx_un]=unique(ChannelID_cell_t);
freq_vec=freq_vec_t(idx_un);
nb_chan=numel(cids);
nb_pings=cell(1,nb_chan);
nb_bad_pings=cell(1,nb_chan);
files_out=cell(1,nb_chan);

freq_vec=cell(1,nb_chan);

for ifreq=1:nb_chan
    idx_freq=strcmpi(ChannelID_cell_t,cids(ifreq));
    nb_pings{ifreq}=nb_pings_t(idx_freq);
    nb_bad_pings{ifreq}=nb_bad_pings_t(idx_freq);
    files_out{ifreq}=files_out_t(idx_freq);
end




end

