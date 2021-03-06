function filter_bottom(trans_obj,varargin)

% input parser
p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'FilterWidth',10,@isnumeric);
parse(p,trans_obj,varargin{:});
results = p.Results;

bot_data = trans_obj.get_bottom_idx();

% filter the bottom
%bot_data_filt=round(filter2_perso(ones(1,results.FilterWidth),bot_data));
bot_data_filt = round(smooth(bot_data,results.FilterWidth));

% create new bottom object with filtered sample_idx
new_bot = bottom_cl('Origin',trans_obj.Bottom.Origin,...
                'Sample_idx',bot_data_filt,...
                'Tag',trans_obj.Bottom.Tag);

% and record in transceiver object
trans_obj.Bottom = new_bot;


end