

function calibration_pkey=add_calibration_to_t_calibration(ac_db_filename,varargin)

p = inputParser;

addRequired(p,'ac_db_filename',@(x) ischar(x)||isa(x,'database.jdbc.connection'));
addParameter(p,'calibration_date',now,@isnumeric);
addParameter(p,'calibration_acquisition_method_type','Standard sphere, in-situ',@ischar);
addParameter(p,'calibration_processing_method','',@ischar);
addParameter(p,'calibration_accuracy_estimate','',@ischar);
addParameter(p,'calibration_report','',@ischar);

addParameter(p,'calibration_setup_key',0,@isnumeric);
addParameter(p,'calibration_frequency',0,@isnumeric);
addParameter(p,'calibration_gain',0,@isnumeric);
addParameter(p,'calibration_sacorrect',0,@isnumeric);
addParameter(p,'calibration_phi_athwart',0,@isnumeric);
addParameter(p,'calibration_phi_along',0,@isnumeric);
addParameter(p,'calibration_phi_athwart_offset',0,@isnumeric);
addParameter(p,'calibration_phi_along_offset',0,@isnumeric);
addParameter(p,'calibration_psi',0,@isnumeric);

addParameter(p,'calibration_comments','',@ischar);

parse(p,ac_db_filename,varargin{:});


struct_in=p.Results;
struct_in=rmfield(struct_in,'ac_db_filename');
fields=fieldnames(struct_in);

for ifi=1:numel(fields)
    if ischar(p.Results.(fields{ifi}))
        struct_in.(fields{ifi})={p.Results.(fields{ifi})};
    else
        struct_in.(fields{ifi})=p.Results.(fields{ifi});
    end
end

struct_in.calibration_date={datestr(struct_in.calibration_date,'yyyy-mm-dd')};

% t=struct2table(struct_in);
% 
% dbconn=connect_to_db(ac_db_filename);  
% dbconn.insert('t_calibration',fieldnames(struct_in),t);
% dbconn.close();
% 
% struct_in=rmfield(struct_in,'calibration_comments');
% [~,calibration_pkey]=get_cols_from_table(ac_db_filename,'t_calibration','input_struct',struct_in,'output_cols',{'calibration_pkey'});
cal.calibration_acquisition_method_type=struct_in.calibration_acquisition_method_type;
cal.calibration_acquisition_method_type_pkey=1;
calibration_acquisition_method_key=insert_data_controlled(ac_db_filename,'t_calibration_acquisition_method_type',cal,cal,'calibration_acquisition_method_type_pkey');

struct_in=rmfield(struct_in,'calibration_acquisition_method_type');
struct_in.calibration_acquisition_method_type_key=calibration_acquisition_method_key;
struct_in_minus_key=rmfield(struct_in,'calibration_comments');

calibration_pkey=insert_data_controlled(ac_db_filename,'t_calibration',struct_in,struct_in_minus_key,'calibration_pkey');


