function [resu, model]=train(model, data)
%[data, model]=train(model, data)
% Template recognizer training method.
% Inputs:
% model     -- A recognizer object.
% data      -- A structure created by databatch.
%
% Returns:
% model     -- The trained model.
% resu      -- A new data structure containing the results.

% Isabelle Guyon -- isabelle@clopinet.com -- October 2011

if model.verbosity>0, fprintf('\n==TR> Training %s for movie type %s... ', class(model), model.movie_type); end

% For all the training examples, create templates (simple average of the
% depth image

Ntr=length(data);
L=zeros(Ntr, 1);
T=cell(Ntr, 1);
for k=1:Ntr
    goto(data, k);
    if strcmp(model.movie_type, 'K')
        % Use the depth image only
        [T{k}, L(k)]=average_movie(data.current_movie.K);
    else
        % Use the RGB image only
        [T{k}, L(k)]=average_movie(data.current_movie.M);
    end
    
end

% Reorder the templates so we don't have to worry
y=get_Y(data);
[s, idx]=sort([y{:}]);
model.T=T(idx);

% Set the average gesture length
model.len=mean(L);    

% Eventually  test the model
if model.test_on_training_data
    resu=test(model, data);
else
    resu=result(data); % Just make a copy
end

if model.verbosity>0, fprintf('\n==TR> Done training %s for movie type %s...\n', class(model), model.movie_type); end


