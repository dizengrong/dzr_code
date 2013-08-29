####################################################################
## @author QingliangCn <qing.liang.cn@gmail.com>
## @datetime 2010-05-30
## @description beam文件被放在ebin下
##
####################################################################
APP_NAME := map
## 定义源码目录列表
SRC_DIRS := src/behaviour/*.erl src/mod/missions_model/*.erl unittest/*.erl src/*.erl src/mod/*.erl src/hook/*.erl
include ../../../hrl/include.mk

##使用通配符方式指定每个文件的编译规则
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/behaviour/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/mod/missions_model/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/mod/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<

$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/hook/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<	
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) unittest/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<	

