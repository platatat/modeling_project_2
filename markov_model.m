n = 8;
rate_x = 0.41;
rate_y = 0.09;

% 0 if no stoplight, otherwise the number of cars that can pass per cycle

% TODO: add extra transition time to stoplight

states = 2*(n^2);

T = zeros(states, states);

for i = 1 : states
	for j = 1 : states
		% current state
		current_x = floor((i-1) / (2*n));
		current_y = mod(floor((i-1) / 2), n);
		current_mode = mod(i-1, 2);

		% target state
		target_x = floor((j-1) / (2*n));
		target_y = mod(floor((j-1) / 2), n);
		target_mode = mod(j-1, 2);
		
		mode_switch = current_mode ~= target_mode;

		if current_mode == 0
			T(i, j) = p_transition(mode_switch, current_x, current_y, target_x, target_y, rate_x, rate_y);
		else
			T(i, j) = p_transition(mode_switch, current_y, current_x, target_y, target_x, rate_y, rate_x);
		end
	end
end

% normalize rows of T to correct for poisson distribution truncation
for row = 1 : states
	T(row,:) = T(row,:) / sum(T(row,:));
end

% find eigenvector corresponding to eigenvalue of 1
[V, D] = eig(transpose(T));

for i = 1 : length(D)
	lambda = D(i, i);
	
	if norm(real(lambda) - 1) < 0.001 && norm(imag(lambda)) < 0.001
		stationary_state = V(:, i);
		stationary_state = stationary_state / sum(stationary_state);
	end
end

S = zeros(n, n);

for i = 1 : states
	x = floor((i-1) / (2*n)) + 1;
	y = mod(floor((i-1) / 2), n) + 1;
	
	S(x, y) = S(x, y) + stationary_state(i);
end

% plot stationary state
h_image = imagesc(flipud(S));

% flip y-axis
h_axis = get(h_image, 'Parent');
y_ticks = get(h_axis, 'YTickLabel');
set(h_axis, 'YTickLabel', flipud(y_ticks));

% set colors and legend
colormap hot;
colorbar;

disp(expected_wait(S, rate_x, rate_y));

function p = p_transition(mode_switch, current_a, current_b, ...
		target_a, target_b, rate_a, rate_b)
	stoplight = 0;
	
	if stoplight > 0
		if mode_switch
			p_mode = 1;
			if target_a == 0
				max_arrivals = stoplight - current_a;
				p_a = poisson_cdf(rate_a, max_arrivals, stoplight);
			else
				arrivals = target_a - current_a + stoplight;
				if arrivals < 0
					p_a = 0;
				else
					p_a = poisson_pdf(rate_a, arrivals, stoplight);
				end
			end
		else
			p_a = 0;
			p_mode = 0;
		end
		
	else
		% number of cars that will pass this step
		if mode_switch || current_a == 0
			crossed = 0;
		else
			crossed = 1;
		end

		% number of x cars that must arrive to get this transition
		a_arrivals = target_a - current_a + crossed;

		% probability of x_arrivals from poisson process
		if a_arrivals < 0
			p_a = 0;
		else
			p_a = poisson_pdf(rate_a, a_arrivals, 1);
		end

		% probability of mode transition
		if mode_switch
			p_mode = p_switch(current_a, current_b);
		else
			p_mode = 1 - p_switch(current_a, current_b);
		end
	end
	
	% number of y cars that must arrive to get this transition
	b_arrivals = target_b - current_b;

	% probability of y_arrivals from poisson processes
	if b_arrivals < 0
		p_b = 0;
	else
		if stoplight > 0
			p_b = poisson_pdf(rate_b, b_arrivals, stoplight);
		else
			p_b = poisson_pdf(rate_b, b_arrivals, 1);
		end
	end
	
	p = p_a * p_b * p_mode;
end

function p = p_switch(a, b)
	switch_threshold = 2;
	if a < b - switch_threshold || a == 0
		p = 1;
	else
		p = 0.0;
	end
end

function t = expected_wait(S, rate_x, rate_y)
	wait = 0;

	for x = 1 : length(S)
		for y = 1 : length(S)
			p = S(x, y);
			wait = wait + p * (x - 1) / rate_x;
			wait = wait + p * (y - 1) / rate_y;
		end
	end
	
	t = wait;
end

function p = poisson_pdf(lambda, k, t)
	p = ((lambda * t) ^ k) * exp(-lambda * t) / factorial(k);
end

function p = poisson_cdf(lambda, k, t)
	c = 0;
	
	for i = 1 : k
		c = c + poisson_pdf(lambda, i, t);
	end
	
	p = c;
end





















