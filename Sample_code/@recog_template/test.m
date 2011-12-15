function resu = test(model, data)
%resu = test(model, data)
% Make predictions with a recog_template method.
% Inputs:
% model -- A recog_template object.
% data -- A data structure.
% Returns:
% data -- The same data structure. WARNING: this follows the convention of
% Spider http://www.kyb.mpg.de/bs/people/spider/ *** The result is in resu.X!!!! ***
% resu.Y are the target values.

% Isabelle Guyon -- October 2011 -- isabelle@clopinet.com

if model.verbosity>0, fprintf('\n==TE> Testing %s for movie type %s... ', class(model), model.movie_type); end

resu=result(data);

% Loop over the samples (we also test the training samples)
Nte=length(data);
for k=1:Nte
    if model.verbosity>0,
        if ~mod(k, round(Nte/10))
            fprintf('%d%% ', round(k/Nte*100));
        end
    end
    
    % Chop the movie in equal pieces and compute the average of the pieces
    goto(data, k);
    if strcmp(model.movie_type, 'K')
        K=data.current_movie.K; % Focus on the depth image only
    else
        K=data.current_movie.M; % Focus on the RGB image only
    end
    L=length(K);            % Compute the length of the movie
    N=min(max(1, round(L/model.len)), 5); % Number of gestures
    step=round(L/N);        % Average duration of a gesture
    b=1; e=step;
    X=cell(N,1);
    X{1}=average_movie(K(b:e));
    for i=2:N
        b=e+1;
        e=min(e+step, L);
        X{i}=average_movie(K(b:e));
    end

    % Compute the similarities with the templates, for each piece
    % and predict the labels Y according to the best match
    Y=zeros(1,N);
    for i=1:N % Number of gestures
        S=[];
        for j=1:length(model.T)
            c=corrcoef(X{i}, model.T{j});
            S(j)=c(1,2);
        end
        % Pick the maximum correlated template
        % Note: we ordered the templates to the index
        % is also the label.
        [m, Y(i)]=max(S);
    end
    set_X(resu, k, Y);
end

if model.verbosity>0, fprintf('\n==TE> Done testing %s for movie type %s... ', class(model), model.movie_type); end
