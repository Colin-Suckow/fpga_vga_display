create_clock -name  clk -period 83.333 [get_ports {clk}]


derive_pll_clocks
	
create_generated_clock -divide 4 -source pll|altpll_component|auto_generated|pll1|clk[0] pixel_clk_cnt[2]


derive_clock_uncertainty