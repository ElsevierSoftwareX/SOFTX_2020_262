function docNode = create_trans_bot_xml_node(trans_obj,docNode,file_id,ver)

% input parser
p = inputParser;
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'docNode',@(docnode) isa(docNode,'org.apache.xerces.dom.DocumentImpl'));
parse(p,trans_obj,docNode);

% intialize bot_xml structure
idx_ping = find(file_id==trans_obj.Data.FileId);
bot_xml.Infos.Freq      = trans_obj.Config.Frequency;
bot_xml.Infos.ChannelID = deblank(trans_obj.Config.ChannelID);
bot_xml.Infos.NbPings   = numel(idx_ping);
bot_xml.Bottom.Tag      = trans_obj.Bottom.Tag(idx_ping);

switch ver
    
    case '0.1'
        time = trans_obj.Time;
        bot_xml.Bottom.Range = trans_obj.get_bottom_range(idx_ping);
        bot_xml.Bottom.Time  = time(idx_ping);
        
    case '0.2'
        bot_xml.Bottom.Ping   = idx_ping - idx_ping(1) + 1;
        bot_xml.Bottom.Sample = trans_obj.get_bottom_idx(idx_ping);
        
        % remove all values where bottom is not defined, or bad ping
        idx_rem = ( (bot_xml.Bottom.Sample==nanmax(trans_obj.Data.Nb_samples)) | isnan(bot_xml.Bottom.Sample) ) & bot_xml.Bottom.Tag==1;
        bot_xml.Bottom.Tag(idx_rem)    = [];
        bot_xml.Bottom.Ping(idx_rem)   = [];
        bot_xml.Bottom.Sample(idx_rem) = [];
        
    case '0.3'
        bot_xml.Bottom.Ping   = idx_ping - idx_ping(1) + 1;
        bot_xml.Bottom.Sample = trans_obj.get_bottom_idx(idx_ping);
        bot_xml.Bottom.E1     = trans_obj.Bottom.E1(idx_ping);
        bot_xml.Bottom.E2     = trans_obj.Bottom.E2(idx_ping);
        
        % remove all values where bottom is not defined, or bad ping
        idx_rem = ( (bot_xml.Bottom.Sample==nanmax(trans_obj.Data.Nb_samples)) | isnan(bot_xml.Bottom.Sample) ) & bot_xml.Bottom.Tag==1;
        bot_xml.Bottom.Tag(idx_rem)    = [];
        bot_xml.Bottom.Ping(idx_rem)   = [];
        bot_xml.Bottom.Sample(idx_rem) = [];
        bot_xml.Bottom.E1(idx_rem) = [];
        bot_xml.Bottom.E2(idx_rem) = [];
        
end

% create the node
docNode = create_bot_xml_node(docNode,bot_xml,ver);

end

