function unpack_idx_struct(s, prefix, postfix, offset)
arguments
    s (1,1) struct
    prefix char = ''
    postfix char = ''
    offset (1,1) double = 0
end

fn = fieldnames(s);

for i = 1:length(fn)
    assignin('caller', [prefix fn{i} postfix], s.(fn{i})+offset)
end