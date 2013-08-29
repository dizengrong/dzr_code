####################################################################
## @author QingliangCn <qing.liang.cn@gmail.com>
## @datetime 2010-05-30
## @description beam文件被放在ebin下
##
####################################################################
APP_NAME := map
## 定义源码目录列表
SRC_DIRS := src/behaviour/*.erl src/mod/missions_model/*.erl src/*.erl src/fight/*.erl src/mod/*.erl src/hook/*.erl src/fb/*.erl
include ../../../hrl/include.mk

##使用通配符方式指定每个文件的编译规则
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/behaviour/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<

$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/mod/missions_model/%.erl $(EBIN_DIR)/b_mission_model.$(EMULATOR) $(EBIN_DIR)/b_mission_tutorial.$(EMULATOR)
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/mod/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/fight/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<

$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/hook/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<	

$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/fb/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<	

